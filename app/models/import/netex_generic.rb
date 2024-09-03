# frozen_string_literal: true

module Import
  class NetexGeneric < Import::Base
    include LocalImportSupport
    include Imports::WithoutReferentialSupport

    attr_accessor :imported_line_ids

    def self.accepts_file?(file)
      case File.extname(file)
      when '.xml'
        true
      when '.zip'
        zip_index = Zip::CentralDirectory.new
        File.open(file) { |f| zip_index.read_from_stream(f) }

        file_entries = zip_index.entries.select(&:file?)
        xml_entries = file_entries.select { |entry| File.extname(entry.name) == '.xml' }

        xml_entries.count.positive? && file_entries.count == xml_entries.count
      else
        false
      end
    rescue StandardError => e
      Chouette::Safe.capture "Error in testing NeTEx (Generic) file: #{file}", e
      false
    end

    def file_extension_whitelist
      %w[zip xml]
    end

    def stop_area_referential
      @stop_area_referential ||= workbench.stop_area_referential
    end

    def line_referential
      @line_referential ||= workbench.line_referential
    end

    def shape_provider
      @shape_provider ||= workbench.default_shape_provider
    end

    def import_without_status
      [
        StopAreaReferential,
        LineReferential,
        ShapeReferential,
        ScheduledStopPoints,
        RoutingConstraintZones
      ].each do |part_class|
        part(part_class).import!
      end

      within_referential do |referential|
        [
          RouteJourneyPatterns,
          TimeTables,
          VehicleJourneys
        ].each do |part_class|
          part(part_class).import!
        end

        referential.ready!
      rescue StandardError => e
        referential.failed!
        raise e
      end

      update_import_status
    end

    def within_referential(&block)
      return unless referential_metadata

      referential_builder.create do |referential|
        self.referential = referential
        referential.switch

        block.call referential

        referential.ready!
      end

      return if referential_builder.valid?

      # create_message has a strange behavior in this context
      messages.build(
        criticity: :error,
        message_key: 'referential_creation_overlapping_existing_referential_block'
      )
      self.overlapping_referential_ids = referential_builder.overlapping_referential_ids
    end

    def referential_metadata
      return unless [imported_line_ids, netex_source.validity_period].all?(&:present?)

      @referential_metadata ||=
        ReferentialMetadata.new line_ids: imported_line_ids, periodes: [netex_source.validity_period]
    end

    # TODO: why the resource statuses are not checked automaticaly ??
    # See CHOUETTE-2747
    def update_import_status
      all_resources_and_messages_statuses =
        messages.map(&:criticity).map(&:upcase) + resources.map(&:status).map(&:to_s)

      resources_and_messages_statuses = all_resources_and_messages_statuses.uniq
      Rails.logger.debug "resource_status: #{resources_and_messages_statuses.inspect}"

      if resources_and_messages_statuses.include?('ERROR')
        self.status = 'failed'
      elsif resources_and_messages_statuses.include?('WARNING')
        self.status = 'warning'
      end

      Rails.logger.debug "@status: #{@status.inspect}"
    end

    def part(part_class)
      # For test, accept a symbol/name in argument
      # For example: part(:line_referential).import!
      unless part_class.is_a?(Class)
        part_class = part_class.to_s

        # :line_referential -> LineReferential
        # :scheduled_stop_points -> ScheduledStopPoints
        plural = part_class.ends_with?('s')
        part_class_name = part_class.classify
        part_class_name = "#{part_class_name}s" if plural

        part_class = self.class.const_get(part_class_name)
      end

      part_class.new self
    end

    class Part
      def initialize(import)
        @import = import
      end
      attr_reader :import

      # To define callback in import!
      include AroundMethod
      around_method :import!

      extend ActiveModel::Callbacks
      define_model_callbacks :import

      def around_import!(&block)
        run_callbacks :import do
          CustomFieldsSupport.within_workgroup(import.workgroup) do
            block.call
          end
        end
      end

      # Save all resources after Part import
      after_import :update_resources

      def update_resources
        import.resources.each do |resource|
          resource.update_metrics
          resource.save
        end
      end

      # Save import after Part import
      # after_import :save_import

      # def save_import
      #   import.save
      # end

      include Measurable
      measure :import!, as: ->(part) { part.class.name.demodulize }

      def code_builder
        @code_builder ||= CodeBuilder.new(import.workgroup.code_spaces)
      end
    end

    class WithResourcePart < Part
      after_import :save_resource

      def save_resource
        @import_resource&.save
      end

      # TODO: manage a given NeTEx resource to save tags
      def create_message(message_key, message_attributes = {})
        attributes = { criticity: :error, message_key: message_key, message_attributes: message_attributes }
        import_resource.messages.build attributes
        import_resource.status = 'ERROR'
      end

      def import_resource_name
        @import_resource_name ||= self.class.name.demodulize
      end

      def import_resource
        @import_resource ||= import.resources.find_or_initialize_by(resource_type: import_resource_name) do |resource|
          resource.name = import_resource_name
          resource.status = 'OK'
        end
      end
    end

    class SynchronizedPart < Part
      include Measurable

      delegate :netex_source, :event_handler, :code_space, :disable_missing_resources?, :strict_mode?,
               :ignore_particulars?, to: :import

      def import!
        synchronization.tap do |sync|
          sync.source = netex_source
          sync.event_handler = event_handler
          sync.code_space = code_space
          sync.default_provider = default_provider
          sync.strict_mode = strict_mode?
          sync.ignore_particulars = ignore_particulars?

          sync.update_or_create
          sync.delete_after_update_or_create if disable_missing_resources?
          sync.after_synchronisation
        end
      end
    end

    # Synchronize models in the StopAreaReferential (StopArea, Entrances, etc)
    # with associated NeTEx resources
    class StopAreaReferential < SynchronizedPart
      delegate :stop_area_provider, to: :import
      delegate :stop_area_referential, to: :import

      def synchronization
        Chouette::Sync::Referential.new(target).tap do |sync|
          sync.synchronize_with Chouette::Sync::StopArea::Netex
          sync.synchronize_with Chouette::Sync::Entrance::Netex
        end
      end

      def target
        if import.update_workgroup_providers?
          stop_area_referential
        else
          stop_area_provider
        end
      end

      def default_provider
        stop_area_provider
      end
    end

    # Synchronize models in the LineReferential (Line, Company, etc)
    # with associated NeTEx resources
    class LineReferential < SynchronizedPart
      delegate :line_provider, to: :import
      delegate :line_referential, to: :import

      def synchronization
        @synchronization ||= Chouette::Sync::Referential.new(target).tap do |sync|
          sync.synchronize_with Chouette::Sync::Company::Netex
          sync.synchronize_with Chouette::Sync::Network::Netex
          sync.synchronize_with Chouette::Sync::LineNotice::Netex
          sync.synchronize_with Chouette::Sync::Line::Netex
        end
      end

      def target
        if import.update_workgroup_providers?
          line_referential
        else
          line_provider
        end
      end

      def default_provider
        line_provider
      end

      def import!
        super

        target
          .lines
          .left_joins(:network)
          .where("networks.id": nil)
          .where.not(network_id: nil)
          .in_batches
          .update_all(network_id: nil)

        target
          .lines
          .left_joins(:company)
          .where("companies.id": nil)
          .where.not(company_id: nil)
          .in_batches
          .update_all(company_id: nil)

        import.imported_line_ids =
          synchronization.sync_for(Chouette::Sync::Line::Netex).imported_line_ids
      end
    end

    class ShapeReferential < SynchronizedPart
      delegate :shape_provider, to: :import

      def synchronization
        Chouette::Sync::Referential.new(shape_provider).tap do |sync|
          sync.synchronize_with Chouette::Sync::PointOfInterest::Netex
        end
      end

      def default_provider
        shape_provider
      end
    end

    class CodeBuilder
      def initialize(code_spaces)
        @code_spaces = code_spaces.index_by(&:short_name)
      end

      def code_space(short_name)
        @code_spaces[short_name]
      end

      def decorate(key_list)
        Decorator.new(key_list, builder: self)
      end

      class Decorator
        def initialize(key_list, builder: nil)
          @key_list = key_list
          @builder = builder
        end

        attr_reader :key_list, :builder

        delegate :code_space, to: :builder, allow_nil: true

        def codes
          key_list.map do |key_value|
            from_key_value(key_value)
          end.compact
        end

        def from_key_value(key_value)
          return unless key_value.type_of_key == 'ALTERNATE_IDENTIFIER'

          code(short_name: key_value.key, value: key_value.value)
        end

        def code(short_name:, value:)
          if value.blank?
            errors << :blank_code
            return
          end

          code_space = code_space(short_name)
          unless code_space
            errors << :unknown_code_space
            return
          end

          code_class.new(code_space: code_space, value: value)
        end

        def code_class
          # TODO: should be defined as Code or ReferentailCode (when needed)
          ::ReferentialCode
        end

        def errors
          @errors ||= []
        end

        def valid?
          errors.empty?
        end
      end
    end

    def referential_inserter
      @referential_inserter ||= ReferentialInserter.new(referential) do |config|
        config.add IdInserter
        config.add TimestampsInserter
        config.add CopyInserter
      end
    end

    module ReferentialPart
      extend ActiveSupport::Concern

      included do
        delegate :referential_inserter, to: :import
      end
    end

    class RouteJourneyPatterns < WithResourcePart
      include ReferentialPart
      delegate :netex_source, :scheduled_stop_points, :line_provider, :index_route_journey_patterns, to: :import

      def route_inserter
        @route_inserter ||= RouteInserter.new(
          referential_inserter, on_invalid: on_invalid, on_save: on_save
        )
      end

      def on_save
        lamba do |model|
          cache_journey_pattern model if model.is_a?(Chouette::JourneyPattern)
        end
      end

      def on_invalid
        lamba do |model|
          case model
          when Chouette::Route
            Rails.logger.debug { "Invalid Model: #{model.errors.inspect} #{model.journey_patterns.map(&:errors).inspect}" }
            create_message :route_invalid
          when Chouette::JourneyPattern
            Rails.logger.debug { "Invalid JourneyPattern: #{model.errors.inspect}" }
            create_message :journey_pattern_invalid
          end
        end
      end

      def import!
        each_route_with_journey_patterns do |netex_route, netex_journey_patterns|
          decorator = Decorator.new(
            netex_route, netex_journey_patterns,
            scheduled_stop_points: scheduled_stop_points,
            route_points: route_points,
            directions: directions,
            destination_displays: destination_displays,
            line_provider: line_provider,
            code_builder: code_builder
          )

          unless decorator.valid?
            decorator.errors.each { |error| create_message error }
            Rails.logger.debug { "Errors found by Decorator for #{netex_route.inspect}: #{decorator.errors.inspect}" }

            next
          end

          route_inserter << decorator.chouette_route
        end

        referential_inserter.flush
      end

      def cache_journey_pattern(journey_pattern)
        index_route_journey_patterns[journey_pattern.registration_number] = {
          journey_pattern_id: journey_pattern.id,
          route_id: journey_pattern.route_id,
          stop_point_ids: journey_pattern.journey_pattern_stop_points.map(&:stop_point_id)
        }
      end

      def each_route_with_journey_patterns(&block)
        netex_source.routes.each do |route|
          journey_patterns = netex_source.journey_patterns.find_by(route_ref: route.id)
          block.call route, journey_patterns
        end
      end

      delegate :route_points, :directions, :destination_displays, to: :netex_source

      class Decorator < SimpleDelegator
        def initialize(route, journey_patterns, scheduled_stop_points: nil, route_points: nil, directions: nil,
                       destination_displays: nil, line_provider: nil, code_builder: nil)
          super route

          @journey_patterns = journey_patterns
          @scheduled_stop_points = scheduled_stop_points
          @route_points = route_points
          @directions = directions
          @destination_displays = destination_displays
          @line_provider = line_provider
          @code_builder = code_builder
        end
        attr_accessor :journey_patterns, :scheduled_stop_points, :route_points, :directions, :line_provider,
                      :destination_displays, :code_builder

        def chouette_line
          line = line_provider.lines.find_by(registration_number: line_ref&.ref)
          add_error :line_not_found unless line

          line
        end

        def chouette_route
          @chouette_route ||= chouette_line.routes.build(route_attributes).tap do |chouette_route|
            chouette_route.journey_patterns = chouette_journey_patterns
          end
        end

        def chouette_journey_patterns
          journey_patterns.map do |netex_journey_pattern|
            JourneyPatternDecorator.new(self, netex_journey_pattern).chouette_journey_pattern
          end
        end

        def route_attributes
          {
            name: chouette_name,
            wayback: wayback,
            published_name: direction_name,
            stop_points: stop_points,
            codes: codes
          }
        end

        def chouette_name
          name || 'Default'
        end

        def wayback
          if Chouette::Route.wayback.values.include?(direction_type)
            direction_type
          else
            # Should be a warning
            # add_error :direction_type_not_found
            :outbound
          end
        end

        def direction
          direction_id = direction_ref&.ref
          return unless direction_id

          direction = directions.find direction_id
          add_error :direction_not_found_in_netex_source unless direction

          direction
        end

        def direction_name
          direction&.name
        end

        def codes
          return [] unless code_builder

          code_builder.decorate(key_list).tap do |decorator|
            errors.concat decorator.errors
          end.codes
        end

        def route_point_refs
          points_in_sequence
            .sort_by { |point_on_route| point_on_route.order.to_i }
            .map { |point_on_route| point_on_route.route_point_ref&.ref }
        end

        def route_scheduled_point_refs
          route_point_refs.map do |route_point_ref|
            route_scheduled_point_ref(route_point_ref)
          end.compact
        end

        def route_scheduled_point_ref(route_point_ref)
          route_point = route_points.find route_point_ref
          unless route_point
            add_error :direction_not_found_in_netex_source
            return nil
          end

          route_point.projections.first&.project_to_point_ref&.ref
        end

        def sequence_merger
          @sequence_merger ||= Sequence::Merger.new.tap do |merger|
            merger << route_scheduled_point_refs

            journey_patterns.each do |netex_journey_pattern|
              scheduled_point_ids =
                netex_journey_pattern
                .points_in_sequence
                .sort_by { |stop_point_in_journey_pattern| stop_point_in_journey_pattern.order.to_i }
                .map { |stop_point_in_journey_pattern| stop_point_in_journey_pattern.scheduled_stop_point_ref&.ref }

              merger << scheduled_point_ids
            end
          end
        end

        def complete_scheduled_stop_points
          sequence_merger.merge.to_a
        end

        def stop_points_by_scheduled_stop_point_id
          @stop_points_by_scheduled_stop_point_id ||= {}.tap do |by_scheduled_stop_point_id|
            complete_scheduled_stop_points.map.with_index do |scheduled_stop_point_id, position|
              if (stop_area_id = scheduled_stop_points[scheduled_stop_point_id]&.stop_area_id)
                stop_point = Chouette::StopPoint.new stop_area_id: stop_area_id, position: position
                by_scheduled_stop_point_id[scheduled_stop_point_id] = stop_point
              else
                add_error :stop_area_found_in_scheduled_stop_points
              end
            end
          end
        end

        def stop_point_for_scheduled_stop_point_id(scheduled_stop_point_id)
          stop_points_by_scheduled_stop_point_id[scheduled_stop_point_id]
        end

        # Route Stop Points ordered by #complete_scheduled_stop_points
        def stop_points
          complete_scheduled_stop_points.map do |scheduled_stop_point_id|
            stop_point_for_scheduled_stop_point_id scheduled_stop_point_id
          end.compact
        end

        def add_error(message_key)
          errors << message_key
        end

        def errors
          @errors ||= []
        end

        def valid?
          chouette_route
          errors.empty?
        end
      end

      class JourneyPatternDecorator < SimpleDelegator
        def initialize(route_decorator, journey_pattern)
          super journey_pattern

          @route_decorator = route_decorator
        end
        attr_accessor :route_decorator

        delegate :destination_displays, :code_builder, to: :route_decorator

        def chouette_journey_pattern
          Chouette::JourneyPattern.new journey_pattern_attributes
        end

        def journey_pattern_attributes
          {
            # TODO: We should not use the JourneyPattern#registration_number
            registration_number: id,
            name: chouette_name,
            published_name: published_name,
            journey_pattern_stop_points: journey_pattern_stop_points,
            codes: codes
          }
        end

        def chouette_name
          name || 'Default'
        end

        def published_name
          destination_display&.front_text
        end

        def codes
          return [] unless code_builder

          code_builder.decorate(key_list).tap do |decorator|
            # errors.concat decorator.errors
          end.codes
        end

        def destination_display
          destination_displays.find(destination_display_ref&.ref)
        end

        def scheduled_point_ids
          @scheduled_point_ids ||=
            points_in_sequence
            .sort_by { |stop_point_in_journey_pattern| stop_point_in_journey_pattern.order.to_i }
            .map { |stop_point_in_journey_pattern| stop_point_in_journey_pattern.scheduled_stop_point_ref&.ref }
        end

        def journey_pattern_stop_points
          scheduled_point_ids.map do |scheduled_point_id|
            stop_point = route_decorator.stop_point_for_scheduled_stop_point_id(scheduled_point_id)
            Chouette::JourneyPatternStopPoint.new stop_point: stop_point
          end
        end
      end

      class Sequence
        # Create a Sequence from an array
        def self.create(*elements)
          links = []
          elements.flatten.each_cons(2) do |from, to|
            links << Link.new(from, to)
          end
          new links
        end

        def initialize(links = [])
          @links = links
          @last = links.last
          freeze
        end
        attr_reader :links, :last

        delegate :empty?, to: :links

        def add(link)
          if empty?
            Sequence.new([link])
          elsif link.from?(last.to)
            Sequence.new(links + [link])
          end
        end

        def to_s
          to_a.join(',')
        end

        def to_a
          return [] if empty?

          links.map(&:from) + [last.to]
        end

        def cover?(from, to)
          from_found = false
          links.each do |link|
            from_found = true if !from_found && link.from?(from)
            return true if from_found && link.to?(to)
          end
          false
        end

        class Link
          def initialize(from, to)
            @from = from
            @to = to
            @definition = "#{from}-#{to}"
            @hash = definition.hash
            freeze
          end
          attr_reader :from, :to, :definition, :hash

          def eql?(other)
            from == other.from && to == other.to
          end

          def from?(value)
            from == value
          end

          def to?(value)
            to == value
          end

          alias to_s definition
          alias inspect definition
        end

        class Merger
          def links
            @links ||= Set.new
          end

          def add(sequence)
            sequence = Sequence.create(sequence)
            links.merge sequence.links
          end
          alias << add

          def merge
            solution = Path.new(Sequence.new, links.dup).complete
            solution&.sequence
          end

          class Path
            def initialize(sequence, pending_links)
              @sequence = sequence
              @pending_links = pending_links
            end
            attr_reader :sequence, :pending_links

            def completed?
              unsolved_links.empty?
            end

            # The current sequence can cover some of the pending links.
            # For example, A,B,C covers A-E, no need to explore it
            def unsolved_links
              @unsolved_links ||=
                if sequence.empty?
                  pending_links
                else
                  pending_links.delete_if do |link|
                    sequence.cover? link.from, link.to
                  end
                end
            end

            # Next possible sequences by following unsolved links
            def next_sequences
              unsolved_links.map do |link|
                sequence.add(link)
              end.compact
            end

            def next_pending_links(next_link)
              unsolved_links.dup.subtract([next_link])
            end

            # Create a Path with each possible next sequences
            def next_paths
              next_sequences.map do |next_sequence|
                next_link = next_sequence.last
                # Remove from pending_links the explored link
                next_pending_links = next_pending_links(next_link)
                Path.new(next_sequence, next_pending_links)
              end
            end

            def complete
              return self if completed?

              next_paths.each do |next_path|
                completed_path = next_path.complete
                return completed_path if completed_path
              end
              nil
            end

            def to_s
              "[#{sequence}] ? #{pending_links.to_a.join(',')}"
            end
          end
        end
      end
    end

    class TimeTables < WithResourcePart
      include ReferentialPart

      delegate :netex_source, :index_time_tables, to: :import

      def import!
        each_day_type_with_assignements_and_periods do |day_type, day_type_assignments, operating_periods|
          decorator = Decorator.new(day_type, day_type_assignments, operating_periods, code_builder: code_builder)

          unless decorator.valid?
            decorator.errors.each { |error| create_message error }
            Rails.logger.debug do
              "Errors found by Decorator for #{[day_type, day_type_assignments,
                                                operating_periods].inspect}: #{decorator.errors.inspect}"
            end

            next
          end

          time_table = decorator.time_table
          unless time_table&.valid?(:inserter)
            Rails.logger.debug { "Invalid TimeTable: #{time_table.errors.inspect}" }
            next
          end

          save(time_table, referential_inserter)

          index_time_tables[day_type.id] = time_table.id
        end

        referential_inserter.flush
      end

      def each_day_type_with_assignements_and_periods(&block)
        netex_source.day_types.each do |day_type|
          day_type_assignments = netex_source.day_type_assignments.find_by(day_type_ref: day_type.id)

          operating_period_ids = day_type_assignments.map { |a| a.operating_period_ref&.ref }
          operating_periods = operating_period_ids.map { |id| netex_source.operating_periods.find id }.reject(&:blank?)

          block.call day_type, day_type_assignments, operating_periods
        end
      end

      def save(time_table, referential_inserter)
        referential_inserter.time_tables << time_table

        time_table.dates.each do |time_table_date|
          time_table_date.time_table_id = time_table.id
          referential_inserter.time_table_dates << time_table_date
        end

        time_table.periods.each do |time_table_period|
          time_table_period.time_table_id = time_table.id
          referential_inserter.time_table_periods << time_table_period
        end

        time_table.codes.each do |code|
          code.resource = time_table
          referential_inserter.codes << code
        end
      end

      class Decorator < SimpleDelegator
        def initialize(day_type, day_type_assignments, operating_periods, code_builder: nil)
          super day_type

          @day_type_assignments = day_type_assignments
          @operating_periods = operating_periods
          @code_builder = code_builder
        end
        attr_reader :day_type_assignments, :code_builder

        def operating_periods
          @operating_periods.reject { |o| o.respond_to? :valid_day_bits }
        end

        def uic_operating_periods
          @operating_periods.select { |o| o.respond_to? :valid_day_bits }
        end

        def valid?
          time_table
          errors.empty?
        end

        def errors
          @errors ||= []
        end

        def days_of_week
          Cuckoo::Timetable::DaysOfWeek.new.tap do |days_of_week|
            %i[monday tuesday wednesday thursday friday saturday sunday].each do |day|
              days_of_week.enable day if send "#{day}?"
            end
          end
        end

        def day_type_assignments_with_date
          @day_type_assignments_with_date ||= day_type_assignments.select(&:date)
        end

        def included_dates
          day_type_assignments_with_date.select(&:available?).map(&:date)
        end

        def excluded_dates
          day_type_assignments_with_date.reject(&:available?).map(&:date)
        end

        def timetable_periods
          operating_periods.map do |operating_period|
            Cuckoo::Timetable::Period.from(operating_period.date_range, days_of_week)
          end
        end

        def uic_days_bits
          uic_operating_periods.map do |operating_period|
            Cuckoo::DaysBit.new(
              from: operating_period.date_range.min,
              bitset: Bitset.from_s(operating_period.valid_day_bits)
            )
          end
        end

        def uic_timetables
          uic_days_bits.map(&:to_timetable)
        end

        def chouette_name
          name || 'Default'
        end

        def codes
          return [] unless code_builder

          code_builder.decorate(key_list).tap do |decorator|
            errors.concat decorator.errors
          end.codes
        end

        def time_table
          @time_table ||= Chouette::TimeTable.new(comment: chouette_name, codes: codes).apply(memory_timetable)
        end

        def base_timetable
          Cuckoo::Timetable.new(
            periods: timetable_periods,
            included_dates: included_dates,
            excluded_dates: excluded_dates
          )
        end

        def memory_timetable
          @memory_timetable ||=
            Cuckoo::Timetable.merge(base_timetable, *uic_timetables).with_uniq_days_of_week.normalize!
        end
      end
    end

    def index_route_journey_patterns
      @index_route_journey_patterns ||= {}
    end

    def index_time_tables
      @index_time_tables ||= {}
    end

    class VehicleJourneys < WithResourcePart
      include ReferentialPart
      delegate :netex_source, :index_route_journey_patterns, :index_time_tables, to: :import

      def import!
        netex_source.service_journeys.each do |service_journey|
          decorator = Decorator.new(service_journey, day_types, index_route_journey_patterns, index_time_tables,
                                    code_builder: code_builder)

          unless decorator.valid?
            decorator.errors.each { |error| create_message error }
            Rails.logger.debug do
              "Errors found by Decorator for #{service_journey.inspect}: #{decorator.errors.inspect}"
            end

            next
          end

          vehicle_journey = decorator.chouette_vehicle_journey
          unless vehicle_journey.valid?(:inserter)
            Rails.logger.debug { "Invalid Vehicle Journey: #{vehicle_journey.errors.inspect}" }
            create_message :vehicle_journey_invalid

            next
          end

          referential_inserter.vehicle_journeys << vehicle_journey

          vehicle_journey.vehicle_journey_at_stops.each do |vehicle_journey_at_stop|
            vehicle_journey_at_stop.vehicle_journey_id = vehicle_journey.id
            referential_inserter.vehicle_journey_at_stops << vehicle_journey_at_stop
          end

          vehicle_journey.vehicle_journey_time_table_relationships.each do |vehicle_journey_time_table|
            vehicle_journey_time_table.vehicle_journey_id = vehicle_journey.id
            referential_inserter.vehicle_journey_time_table_relationships << vehicle_journey_time_table
          end

          vehicle_journey.codes.each do |code|
            code.resource = vehicle_journey
            referential_inserter.codes << code
          end
        end

        referential_inserter.flush
      end

      def day_types
        @day_types ||= netex_source.day_types
      end

      class Decorator < SimpleDelegator
        def initialize(service_journey, day_types, index_route_journey_patterns, index_time_tables, code_builder: nil)
          super service_journey

          @day_types = day_types
          @index_route_journey_patterns = index_route_journey_patterns
          @index_time_tables = index_time_tables
          @code_builder = code_builder
        end
        attr_reader :day_types, :index_route_journey_patterns, :index_time_tables, :code_builder

        def valid?
          chouette_vehicle_journey
          errors.empty?
        end

        def errors
          @errors ||= []
        end

        def route_id
          @route_id ||= begin
            route_id = route_journey_pattern(:route_id)
            errors << :route_not_found unless route_id
            route_id
          end
        end

        def netex_journey_pattern_ref
          journey_pattern_ref&.ref
        end

        def route_journey_pattern(attribute)
          @route_journey_pattern ||= index_route_journey_patterns[netex_journey_pattern_ref]
          @route_journey_pattern[attribute] if @route_journey_pattern
        end

        def journey_pattern_id
          @journey_pattern_id ||= begin
            journey_pattern_id = route_journey_pattern(:journey_pattern_id)
            errors << :journey_pattern_not_found unless journey_pattern_id
            journey_pattern_id
          end
        end

        def vehicle_journey_attributes
          {
            route_id: route_id,
            journey_pattern_id: journey_pattern_id,
            published_journey_name: name,
            published_journey_identifier: id,
            vehicle_journey_at_stops: vehicle_journey_at_stops,
            vehicle_journey_time_table_relationships: vehicle_journey_time_table_relationships,
            codes: codes
          }
        end

        def chouette_vehicle_journey
          @chouette_vehicle_journey ||= Chouette::VehicleJourney.new vehicle_journey_attributes
        end

        def chouette_stop_point_ids
          @chouette_stop_point_ids ||= route_journey_pattern(:stop_point_ids) || []
        end

        def codes
          return [] unless code_builder

          code_builder.decorate(key_list).tap do |decorator|
            errors.concat decorator.errors
          end.codes
        end

        def vehicle_journey_at_stops
          unless chouette_stop_point_ids.count == passing_times.count
            errors << :number_passing_times_incoherent
            return []
          end

          [].tap do |vehicle_journey_at_stops|
            chouette_stop_point_ids.each_with_index do |stop_point_id, index|
              passing_time = passing_times[index]
              vehicle_journey_at_stops << Chouette::VehicleJourneyAtStop.new(
                stop_point_id: stop_point_id,
                arrival_time: passing_time.arrival_time,
                departure_time: passing_time.departure_time,
                arrival_day_offset: passing_time.arrival_day_offset || 0,
                departure_day_offset: passing_time.departure_day_offset || 0
              )
            end
          end
        end

        def vehicle_journey_time_table_relationships
          @vehicle_journey_time_table_relationships ||= [].tap do |vehicle_journey_time_tables|
            day_types.map do |day_type|
              time_table_id = index_time_tables[day_type.id]
              if time_table_id
                vehicle_journey_time_tables << Chouette::TimeTablesVehicleJourney.new(time_table_id: time_table_id)
              else
                errors << :time_table_not_found
              end
            end
          end
        end
      end
    end

    def scheduled_stop_points
      @scheduled_stop_points ||= {}
    end

    class ScheduledStopPoint
      def initialize(id:, stop_area_id:)
        @id = id
        @stop_area_id = stop_area_id
      end

      attr_accessor :id, :stop_area_id
    end

    class ScheduledStopPoints < WithResourcePart
      delegate :netex_source, :code_space, :stop_area_provider, :scheduled_stop_points, to: :import

      def import!
        netex_source.passenger_stop_assignments.each do |stop_assignment|
          scheduled_stop_point_id = stop_assignment.scheduled_stop_point_ref&.ref
          stop_area_code = (stop_assignment.quay_ref || stop_assignment.stop_place_ref)&.ref

          unless stop_area_code
            create_message :stop_area_code_empty
            next
          end

          if (stop_area = stop_area_provider.stop_areas.find_by(registration_number: stop_area_code).presence)
            scheduled_stop_point = ScheduledStopPoint.new(id: scheduled_stop_point_id, stop_area_id: stop_area.id)
            scheduled_stop_points[scheduled_stop_point.id] = scheduled_stop_point
          else
            create_message :stop_area_not_found, code: stop_area_code
            next
          end
        end
      end
    end

    class RoutingConstraintZones < WithResourcePart
      delegate :netex_source, :code_space, :scheduled_stop_points, :line_provider,
               :stop_area_provider, :event_handler, to: :import

      def import!
        netex_source.routing_constraint_zones.each do |zone|
          decorator = Decorator.new(zone, line_provider: line_provider,
                                          stop_area_provider: stop_area_provider,
                                          code_space: code_space,
                                          scheduled_stop_points: scheduled_stop_points)

          unless decorator.valid?
            create_message :invalid_netex_source_routing_constraint_zone
            next
          end

          line_routing_constraint_zone = decorator.line_routing_constraint_zone

          # TODO: share error creating from model errors
          unless line_routing_constraint_zone.valid?
            line_routing_constraint_zone.errors.each_key do |attribute|
              attribute_value = line_routing_constraint_zone.send(attribute)

              # FIXME: little trick to avoid message like:
              # L'attribut lines ne peut avoir la valeur '#<HasArrayOf::AssociatedArray::Relation:0x00007f82be1a03e0>'
              attribute_value = '' if attribute_value.blank?
              create_message :invalid_model_attribute, attribute_name: attribute, attribute_value: attribute_value
            end
            next
          end

          line_routing_constraint_zone.save
        end
      end

      class Decorator < SimpleDelegator
        def initialize(zone, line_provider: nil, stop_area_provider: nil, code_space: nil, scheduled_stop_points: nil)
          super zone
          @line_provider = line_provider
          @stop_area_provider = stop_area_provider
          @code_space = code_space
          @scheduled_stop_points = scheduled_stop_points
        end
        attr_accessor :zone, :line_provider, :code_space, :scheduled_stop_points, :stop_area_provider

        def code_value
          id
        end

        def line_codes
          lines.map(&:ref)
        end

        def chouette_lines
          line_provider.lines.where(registration_number: line_codes)
        end

        def scheduled_stop_point_ids
          members.map(&:ref)
        end

        def member_scheduled_stop_points
          scheduled_stop_points.values_at(*scheduled_stop_point_ids).compact
        end

        def stop_area_ids
          member_scheduled_stop_points.map(&:stop_area_id)
        end

        def stop_areas
          stop_area_provider.stop_areas.where(id: stop_area_ids)
        end

        def valid?
          code_value.present? && line_codes.present? && scheduled_stop_point_ids.present?
        end

        def attributes
          {
            name: name,
            stop_areas: stop_areas,
            lines: chouette_lines,
            line_referential: line_referential,
            line_provider: line_provider
          }
        end

        delegate :line_referential, to: :line_provider

        def line_routing_constraint_zone
          # TODO: CHOUETTE-3346 this seems untested
          line_provider.line_routing_constraint_zones.first_or_initialize_by_code(code_space, code_value) do |zone|
            zone.attributes = attributes
          end
        end
      end
    end

    def event_handler
      @event_handler ||= EventHandler.new self
    end

    class EventHandler < Chouette::Sync::Event::Handler
      def initialize(import)
        @import = import
      end
      attr_reader :import

      def handle(event)
        Rails.logger.debug { "Broadcast Synchronization Event #{event.inspect}" }
        return unless event.resource

        EventProcessor.new(event, resource(event.resource.class)).tap do |processor|
          processor.process

          import.status = 'failed' if processor.has_error?
        end
      end

      # Create a Import::Resource
      def resource(netex_resource_class)
        # StopPlace, Quay, ...
        human_netex_resource_name = netex_resource_class.name.demodulize.pluralize

        import.resources.find_or_initialize_by(resource_type: human_netex_resource_name) do |resource|
          resource.name = human_netex_resource_name
          resource.status = 'OK'
        end
      end

      class EventProcessor
        def initialize(event, resource)
          @event = event
          @resource = resource
          @has_error = false
        end

        attr_reader :event, :resource
        attr_writer :has_error

        def has_error?
          @has_error
        end

        def process
          if event.has_error?
            process_error
          elsif event.type.create? || event.type.update?
            process_create_or_update
          end

          # TODO: As ugly as necessary
          # Need to save resource because it's used in resource method
          resource.save
        end

        def process_create_or_update
          resource.inc_rows_count event.count
        end

        def process_error
          self.has_error = true
          resource.status = 'ERROR'
          event.errors.each do |attribute, errors|
            errors.each do |error|
              resource.messages.build(
                criticity: :error,
                message_key: :invalid_model_attribute,
                message_attributes: {
                  attribute_name: attribute,
                  attribute_value: error[:value]
                },
                resource_attributes: event.resource.tags
              )
            end
          end
        end
      end
    end

    def netex_source
      @netex_source ||= ::Netex::Source.new(include_raw_xml: store_xml?).tap do |source|
        source.transformers << ::Netex::Transformer::Uniqueness.new
        source.transformers << ::Netex::Transformer::LocationFromCoordinates.new
        source.transformers << ::Netex::Transformer::Indexer.new(::Netex::JourneyPattern, by: :route_ref)
        source.transformers << ::Netex::Transformer::Indexer.new(::Netex::DayTypeAssignment, by: :day_type_ref)

        source.read(local_file.path, type: file_extension)
      end
    end

    def line_ids
      []
    end
  end
end
