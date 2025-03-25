# frozen_string_literal: true

# Selects which models need to be included into an Export
module Export
  module Scope
    def self.build(referential, **options)
      Options.new(referential, options).scope
    end

    class Builder
      def initialize(referential)
        @scope = All.new(referential)
        yield self if block_given?
      end

      def internal_scopes
        @internal_scopes ||= []
      end

      def current_scope
        internal_scopes.last || @scope
      end

      def scheduled
        internal_scopes << Scheduled.new(current_scope)
        self
      end

      def lines(line_ids)
        internal_scopes << Lines.new(current_scope, line_ids)
        self
      end

      def period(date_range)
        internal_scopes << DateRange.new(current_scope, date_range)
        self
      end

      def stateful(export_id)
        internal_scopes << Stateful.new(current_scope, export_id)
        self
      end

      def scope
        @scope = current_scope

        internal_scopes.each do |scope|
          scope.final_scope = @scope if scope.respond_to? :final_scope=
        end

        @scope
      end
    end

    class Options
      attr_reader :referential
      attr_accessor :duration, :date_range, :line_ids, :line_provider_ids, :company_ids, :export_id, :stateful

      def initialize(referential, attributes = {})
        @referential = referential

        @stateful = true
        attributes.each { |k, v| send "#{k}=", v }
      end

      def line_ids
        @line_ids || companies_line_ids || line_provider_line_ids
      end

      def line_provider_line_ids
        referential.line_referential.lines.where(line_provider: line_provider_ids).pluck(:id) if line_provider_ids
      end

      def companies_line_ids
        referential.line_referential.lines.where(company: company_ids).pluck(:id) if company_ids
      end

      def builder
        @builder ||= Builder.new(referential) do |builder|
          builder.lines(line_ids) if line_ids
          builder.period(date_range) if date_range
          builder.scheduled
          if stateful
            builder.stateful(export_id)
          else
            Rails.logger.debug 'Disable stateful scope'
          end
        end
      end

      delegate :scope, to: :builder
    end

    class All
      attr_reader :referential

      def initialize(referential)
        @referential = referential
      end

      delegate :workgroup, :workbench, :line_referential, :stop_area_referential, :metadatas, to: :referential
      delegate :shape_referential, :fare_referential, to: :workgroup

      delegate :line_groups, :companies, :networks, :line_notices, :booking_arrangements, to: :line_referential
      delegate :stop_area_groups, :entrances, to: :stop_area_referential

      delegate :shapes, :point_of_interests, to: :shape_referential
      delegate :fare_zones, :fare_products, :fare_validities, to: :fare_referential

      delegate :codes, :contracts, to: :workgroup

      delegate :vehicle_journeys, :vehicle_journey_at_stops, :journey_patterns, :stop_points,
               :time_tables, :routes, :referential_codes, :routing_constraint_zones, to: :referential

      def organisations
        # Find organisations which provided metadata in the referential
        # Only works for merged/aggregated datasets
        organisation_ids = metadatas.joins(referential_source: :organisation).distinct.pluck('organisations.id')

        # Use the Referential owner in fallback
        organisation_ids = [referential.organisation_id] if organisation_ids.empty?

        workgroup.organisations.where(id: organisation_ids)
      end

      def stop_areas
        (workbench || stop_area_referential).stop_areas
      end

      def lines
        (workbench || line_referential).lines
      end

      def validity_period
        @validity_period ||= Period.for_range(referential.validity_period)
      end
    end

    # By default a Scope uses the current_scope collection.
    class Base < SimpleDelegator
      def initialize(current_scope)
        super current_scope
        @current_scope = current_scope
      end

      delegate :empty?, to: :vehicle_journeys

      attr_reader :current_scope

      def vehicle_journeys
        @vehicle_journeys ||= current_scope.vehicle_journeys
      end

      def inspect
        "#<#{self.class}:#{object_id} @current_scope=#{current_scope.inspect}>"
      end
    end

    class Scheduled < Base
      attr_writer :final_scope

      def final_scope
        @final_scope || current_scope
      end

      def vehicle_journeys
        current_scope.vehicle_journeys.scheduled(final_scope.time_tables)
      end

      delegate :vehicle_journeys, to: :final_scope, prefix: true

      def lines
        current_scope.lines.where(id: routes.select(:line_id).distinct)
      end

      def line_groups
        current_scope.line_groups.where(
          id: ::LineGroup::Member.where(line_id: lines.select(:id).distinct).select(:group_id).distinct
        )
      end

      def companies
        current_scope.companies.where(id: company_ids).or(
          current_scope.companies.where(id: secondary_company_ids)
        ).distinct
      end

      def company_ids
        lines.where.not(company_id: nil).select(:company_id).distinct
      end

      def secondary_company_ids
        lines.where.not(secondary_company_ids: nil).select('unnest(secondary_company_ids)').distinct
      end

      def networks
        current_scope.networks.where(id: lines.where.not(network_id: nil).select(:network_id).distinct)
      end

      def vehicle_journey_at_stops
        current_scope.vehicle_journey_at_stops.where(vehicle_journey: final_scope_vehicle_journeys)
      end

      def routes
        current_scope.routes.where(id: final_scope_vehicle_journeys.select(:route_id).distinct)
      end

      def journey_patterns
        current_scope.journey_patterns.where(id: final_scope_vehicle_journeys.select(:journey_pattern_id).distinct)
      end

      def shapes
        current_scope.shapes.where(id: journey_patterns.select(:shape_id).distinct)
      end

      def stop_points
        current_scope.stop_points.distinct.where(route: routes)
      end

      def stop_areas
        current_scope.stop_areas.where(Chouette::StopArea.arel_table[:id].in(stop_area_ids))
      end

      def stop_area_groups
        current_scope.stop_area_groups.where(
          id: ::StopAreaGroup::Member.where(::StopAreaGroup::Member.arel_table[:stop_area_id].in(stop_area_ids))
                                     .select(:group_id).distinct
        )
      end

      def stop_points_stop_area_ids
        stop_points.select(:stop_area_id).distinct
      end

      def specific_vehicle_journey_at_stops_stop_area_ids
        vehicle_journey_at_stops.where.not(stop_area_id: nil).select(:stop_area_id).distinct
      end

      def entrances
        current_scope.entrances.where(stop_area: stop_areas)
      end

      def routing_constraint_zones
        current_scope.routing_constraint_zones.where(route: routes)
      end

      def fare_products
        current_scope.fare_products.where(company: companies).or(current_scope.fare_products.where(company: nil))
      end

      def fare_validities
        # TODO: we should filter Validities according zones & exported stop areas
        current_scope.fare_validities.by_products(fare_products)
      end

      def contracts
        current_scope.contracts.with_lines(lines)
      end

      def line_notices
        current_scope.line_notices.with_lines(lines)
      end

      private

      def stop_area_ids
        Arel::Nodes::Union.new(
          stop_points_stop_area_ids.arel.ast,
          specific_vehicle_journey_at_stops_stop_area_ids.arel.ast
        )
      end
    end

    # Selects VehicleJourneys in a Date range
    class DateRange < Base
      attr_reader :date_range

      def initialize(current_scope, date_range)
        super current_scope
        @date_range = date_range
      end

      def time_tables
        current_scope.time_tables.applied_at_least_once_in(date_range)
      end

      def vehicle_journeys
        current_scope.vehicle_journeys.with_matching_timetable(date_range)
      end

      def metadatas
        current_scope.metadatas.include_daterange(date_range)
      end

      def validity_period
        current_scope.validity_period & date_range
      end
    end

    # Selects VehicleJourneys associated to selected lines
    class Lines < Base
      attr_reader :selected_line_ids

      def initialize(current_scope, selected_line_ids)
        super current_scope
        @selected_line_ids = selected_line_ids
      end

      def vehicle_journeys
        current_scope.vehicle_journeys.with_lines(selected_line_ids)
      end

      def metadatas
        current_scope.metadatas.with_lines(selected_line_ids)
      end

      def contracts
        current_scope.contracts.with_lines(lines)
      end

      def line_notices
        current_scope.line_notices.joins(:lines).where('lines.id' => selected_line_ids).distinct
      end

      def time_tables
        current_scope.time_tables.where(id: time_table_ids)
      end

      private

      def time_table_ids
        current_scope.time_tables.joins(:lines).where('lines.id' => selected_line_ids).distinct.select(:id)
      end
    end

    class Stateful < Base
      attr_reader :export_id, :loaders

      LOADED_CLASSES = [Chouette::VehicleJourney, Chouette::TimeTable]

      def initialize(current_scope, export_id = nil)
        super current_scope
        @export_id = export_id
        @loaders = {}
      end

      LOADED_CLASSES.each do |loaded_class|
        define_method loaded_class.model_name.collection do
          @loaders[loaded_class] ||= Loader.new(current_scope, export_id, loaded_class).loaded_models
        end
      end

      class Loader
        def initialize(current_scope, export_id, loaded_class)
          @current_scope = current_scope
          @export_id = export_id
          @loaded_class = loaded_class
        end
        attr_reader :export_id, :current_scope, :loaded_class

        def loaded_models
          unless @loaded
            columns = %w[uuid export_id model_type model_id].reject do |c|
              c == 'export_id' && export_id.nil?
            end.join(',')
            constants = ["'#{uuid}'", export_id, "'#{loaded_class_name}'"].compact
            models = model_scope.select(constants, :id)

            if sql = models.to_sql.presence
              query = <<~SQL
                INSERT INTO public.exportables (#{columns}) #{sql}
              SQL
              ActiveRecord::Base.connection.execute query
              ActiveRecord::Base.connection.execute 'ANALYZE public.exportables'
            end

            @loaded = true
          end

          exportable_models
        end

        def exportable_models
          @exportable_models ||=
            begin
              exportables = Exportable.where(uuid: uuid, model_type: loaded_class_name, processed: false)
              loaded_class.where(id: exportables.select(:model_id))
            end
        end

        private

        def loaded_class_name
          @loaded_class_name ||= loaded_class.name
        end

        def model_scope
          @model_scope ||= current_scope.send(loaded_class.model_name.collection)
        end

        def uuid
          @uuid ||= SecureRandom.uuid
        end
      end
    end
  end
end
