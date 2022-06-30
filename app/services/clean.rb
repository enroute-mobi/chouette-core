#
# Provides all Clean strategies
#
# = Examples
#
# Clean timetables for a date range for a given Line
#
#   scope = Clean::Scope::Line.new(Clean::Scope::Referential.new(referential), line)
#   Clean::Timetable::InPeriod.new(scope, (Date.today-30)..Date.today).clean!
#
module Clean
  class Base
    include Measurable

    attr_reader :scope
    def initialize(scope)
      @scope = scope
    end

    include AroundMethod
    around_method :clean!

    def around_clean!(&block)
      scope.switch(&block)
    end
  end

  # Manages/restricts the scope of cleaned data
  module Scope

    class Referential
      attr_reader :referential
      def initialize(referential)
        @referential = referential
      end

      delegate :routes, :vehicle_journeys, :journey_patterns, :service_counts,
               :time_tables, :time_table_dates, :time_table_periods, :metadatas,
               to: :referential

      alias timetables time_tables
      alias timetable_periods time_table_periods
      alias timetable_dates time_table_dates

      def restricted_metadata(metadata)
        metadata
      end

      def switch(&block)
        referential.switch(&block)
      end

      def unmodifiable_timetables?
        false
      end

    end

    class Line

      def initialize(scope, line_or_line_id)
        line_id = line_or_line_id.try(:id) || line_or_line_id
        @scope, @line_id = scope, line_id
      end
      attr_reader :scope, :line_id

      delegate :switch, to: :scope

      def routes
        scope.routes.where(line_id: line_id)
      end

      def journey_patterns
        scope.journey_patterns.where(route: routes)
      end

      # Returns all Vehicle Journeys associated to the selected Line
      def vehicle_journeys
        scope.vehicle_journeys.where(route: routes)
      end

      # Returns all TimeTables associated to the selected Line (via the Vehicle Journeys)
      def timetables
        scope.timetables.joins(:vehicle_journeys).where('vehicle_journeys.id' => vehicle_journeys)
      end

      def timetable_periods
        scope.timetable_periods.where(time_table: timetables)
      end

      def timetable_dates
        scope.timetable_dates.where(time_table: timetables)
      end

      def service_counts
        scope.service_counts.for_lines(line_id)
      end

      def metadatas
        scope.metadatas.include_lines([line_id])
      end

      # Returns a (unsaved) metadata which only covers the current
      # scope and which can be modified/deleted safely, without
      # changing a metadata out of the scope
      def restricted_metadata(metadata)
        # return nil unless metadata.line_ids.include? line_id
        return metadata if metadata.line_ids == [ line_id ]

        restricted = metadata.dup
        restricted.id = nil
        restricted.line_ids = [line_id]

        metadata.line_ids.delete line_id
        metadata.save!

        restricted
      end

      # Find TimeTables which are used by lines outside of this scope
      def unmodifiable_timetables?
        timetables.shared_by_several_lines?
      end
    end

  end

  class InPeriod < Base
    attr_accessor :period
    def initialize(scope, period)
      super scope
      @period = period
    end

    def clean!
      [
        Timetable::InPeriod.new(scope, period),
        ServiceCount::InPeriod.new(scope, period),
        VehicleJourney::WithoutTimetable.new(scope),
        JourneyPattern::WithoutVehicleJourney.new(scope),
        Route::WithoutJourneyPattern.new(scope),
      ].each(&:clean!)
    end
  end

  module VehicleJourney
    class WithoutTimetable < Base
      def clean!
        scope.vehicle_journeys.without_any_time_table.clean!
      end
    end
  end

  module JourneyPattern
    class WithoutVehicleJourney < Base
      def clean!
        scope.journey_patterns.without_any_vehicle_journey.clean!
      end
    end
  end

  module Route
    class WithoutJourneyPattern < Base
      def clean!
        scope.routes.without_any_journey_pattern.clean!
      end
    end
  end

  module ServiceCount
    class InPeriod < Base
      attr_accessor :period
      def initialize(scope, period)
        super scope
        @period = period
      end

      def service_counts
        scope.service_counts.between(period.min, period.max)
      end

      def clean!
        service_counts.delete_all
      end
    end
  end

  module Timetable
    # Delete TimeTables without periods and dates
    #
    # Removes associations with vehicle journeys
    class Empty < Base
      def clean!
        scope.timetables.empty.delete_all
      end
    end

    # Delete or truncate TimeTables with periods or/and dates in the given period
    class InPeriod < Base
      attr_accessor :period
      def initialize(scope, period)
        super scope
        @period = period
      end

      def clean!
        # TODO Duplicate TimeTables used by another Line in the same Period
        if scope.unmodifiable_timetables?
          raise "Can't modify shared timetables"
        end

        # Delete dates
        Date::InPeriod.new(scope, period).clean!
        # Delete and truncate periods in the period
        Period::InPeriod.new(scope, period).clean!

        # Remove TimeTables without dates or periods
        Empty.new(scope).clean!

        scope.timetables.update_shortcuts
      end

    end

    module Date
      class InPeriod < Base
        attr_accessor :period
        def initialize(scope, period)
          super scope
          @period = period
        end

        def dates
          scope.timetable_dates.in_date_range(period)
        end

        def clean!
          dates.delete_all
        end
      end
    end

    module Period
      class InPeriod < Base
        attr_accessor :period
        def initialize(scope, period)
          super scope
          @period = period
        end

        delegate :timetable_periods, to: :scope

        # Delete periods which starts and finishs into the period
        def clean_into
          criteria = [ 'period_start between :min and :max and period_end between :min and :max', min: period.min, max: period.max ]
          timetable_periods.where(criteria).delete_all
        end

        # Truncate periods which starts before the period/range and finishs into the period/range
        def truncate_before
          criteria = [ 'period_start < :min and period_end between :min and :max', min: period.min, max: period.max ]
          timetable_periods.where(criteria).update_all period_end: period.min - 1
        end

        # Truncate periods which starts into the period and finishs after the period
        def truncate_after
          criteria = [ 'period_start between :min and :max and period_end > :max', min: period.min, max: period.max ]
          timetable_periods.where(criteria).update_all period_start: period.max + 1
        end

        def split_over
          criteria = [ 'period_start < :min and period_end > :max', min: period.min, max: period.max ]
          scope.timetable_periods.where(criteria).select(:id, :time_table_id, :period_start, :period_end).find_each do |initial_period|
            # Duplicate the period to create a new TimeTablePeriod after the clean period
            after_period = initial_period.dup
            # Update period_end of the initial period
            initial_period.update period_end: period.min - 1
            after_period.id = nil
            after_period.period_start = period.max + 1
            after_period.save!
          end
        end

        def clean!
          clean_into
          truncate_before
          truncate_after
          split_over

          scope.timetable_periods.transform_in_dates
        end
      end

    end
  end

  module Metadata
    class Cleaner
      def initialize(scope)
        @scope = scope
      end
      attr_reader :scope

      # Modify the given metadata (after scope restriction)
      # Save it or destroy it if empty
      def clean(metadata, &block)
        metadata = scope.restricted_metadata(metadata)

        block.call metadata

        if metadata.periodes.empty?
          metadata.destroy
        else
          metadata.save!
        end
      end
    end

    class Before < Base
      attr_accessor :before
      def initialize(scope, before)
        super scope
        @before = before
      end

      # Truncate or remove the period from the given metadata (after scope restriction)
      def clean_metadata(metadata)
        before_period = Range.new(metadata.bounds.min, before)

        Cleaner.new(scope).clean(metadata) do |m|
          m.periodes = Range.remove(m.periodes, before_period)
        end
      end

      def metadatas
        scope.metadatas.start_before before
      end

      def clean!
        metadatas.find_each do |metadata|
          clean_metadata metadata
        end
      end
    end

    class InPeriod < Base
      attr_accessor :period
      def initialize(scope, period)
        super scope
        @period = period
      end

      # Remove the period from the given metadata (after scope restriction)
      def clean_metadata(metadata)
        Cleaner.new(scope).clean(metadata) do |m|
          m.periodes = Range.remove(m.periodes, period)
        end
      end

      def metadatas
        scope.metadatas.include_daterange period
      end

      def clean!
        metadatas.find_each do |metadata|
          clean_metadata metadata
        end
      end
    end
  end
end
