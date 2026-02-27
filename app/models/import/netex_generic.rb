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
        file_entries.any? { |entry| File.extname(entry.name) == '.xml' }
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

    def fare_provider
      @fare_provider || workbench.default_fare_provider
    end

    def import_without_status
      [
        StopAreaReferential,
        LineReferential,
        ShapeReferential,
        FareReferential,
        ScheduledStopPoints,
        RoutingConstraintZones
      ].each do |part_class|
        part(part_class).import!
      end

      within_referential do |referential|
        [
          RouteJourneyPatterns,
          TimeTables,
          ReferentialNotices,
          VehicleJourneys,
          VehicleJourneyStopAssignments
        ].each do |part_class|
          part = part(part_class)
          # TODO: could be manage by Import::Part constructor .. but requires several changes
          part.referential = referential
          part.import!
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
        self.imported_line_ids |= referential_metadata.line_ids

        referential.switch

        block.call referential

        referential.ready!
      end

      return if referential_builder.valid?

      referential_builder.errors.each do |message_key|
        messages.build(
          criticity: :error,
          message_key: message_key
        )
      end

      self.overlapping_referential_ids = referential_builder.overlapping_referential_ids
    end

    def referential_metadata
      @referential_metadata ||= ReferentialMetadataBuilder.new(netex_source, lookup).referential_metadata
    end

    class ReferentialMetadataBuilder
      def initialize(source, lookup)
        @source = source
        @lookup = lookup
      end
      attr_reader :source, :lookup

      def source_decorator
        @source_decorator ||= SourceDecorator.new(source)
      end

      def route_line_ids
        @route_line_ids ||= lookup.lines.find_ids(source_decorator.line_refs)
      end

      def validity_period
        @validity_period ||= netex_validity_period || day_types_overall_period
      end

      # Overall period defined by all NeTEx DayType validity periods
      def netex_validity_period
        PeriodBuilder.add(source_decorator.day_type_valid_periods).range
      end

      # Overall period defined by all NeTEx DayTypeAssignement/OperatingPeriod instances
      def day_types_overall_period
        PeriodBuilder
          .add(source_decorator.operating_period_ranges)
          .add(source_decorator.day_type_assignment_ranges)
          .range
      end

      def referential_metadata
        return unless [route_line_ids, validity_period].all?(&:present?)

        @referential_metadata ||=
          ReferentialMetadata.new line_ids: route_line_ids, periodes: [validity_period]
      end

      class SourceDecorator < SimpleDelegator
        def line_refs
          @line_refs ||= routes.map { |r| r.line_ref&.ref }.compact.uniq
        end

        def day_type_valid_periods
          day_types.map { |d| PeriodBuilder.add(d.validity_period).add(d.frame_validity_period).range }.compact
        end

        def operating_period_ranges
          operating_periods.map(&:date_range)
        end

        def day_type_assignments_with_date
          day_type_assignments.select do |assignment|
            assignment.date && assignment.available?
          end
        end

        def day_type_assignment_ranges
          day_type_assignments_with_date.map do |assignment|
            Range.new assignment.date, assignment.date
          end
        end
      end

      class PeriodBuilder
        attr_accessor :min, :max

        def add(*ranges)
          ranges.flatten.compact.each do |range|
            self.min = [min, range.min].compact.min
            self.max = [max, range.max].compact.max
          end

          self
        end

        def self.add(*ranges)
          new.add(*ranges)
        end

        def range
          min..max if min && max
        end
      end
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

    module Decorate
      def decorate(resource, decorator_class = default_decorator_class, **attributes)
        decorator_class.new(resource, **default_decorator_attributes.merge(attributes))
      end

      def default_decorator_attributes # rubocop:disable Metrics/MethodLength
        {
          code_builder: code_builder,
          override_internal_identifiers: override_internal_identifiers?
        }.tap do |attributes|
          %i[
            lookup
            code_space
            line_provider
            stop_area_provider
            scheduled_stop_points
          ].each do |attr|
            attributes[attr] = send(attr) if respond_to?(attr)
          end
        end
      end

      def default_decorator_class
        @default_decorator_class ||= self.class.const_get(:Decorator)
      end
    end

    class ResourceDecorator < Import::Decorator
      include Decorate

      attr_accessor :code_builder, :scheduled_stop_points,
                    :override_internal_identifiers,
                    :line_provider, :stop_area_provider # TODO: waiting for lookup whole integration

      alias override_internal_identifiers? override_internal_identifiers

      def chouette_name
        name || 'Default'
      end

      def chouette_attributes
        {
          codes: codes
        }.tap do |attributes|
          attributes[:objectid] = id if override_internal_identifiers?
        end
      end

      def codes
        [ code, *alternate_codes ].compact
      end

      def code
        ReferentialCode.new(code_space: code_space, value: id) if id
      end

      def alternate_codes
        return [] unless code_builder

        code_builder.decorate(key_list).tap do |decorator|
          errors.concat decorator.errors
        end.codes
      end

      def validate
        super
        chouette_model
      end
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

    class Part < Import::Part
      delegate :override_internal_identifiers?, to: :import

      include Decorate

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
      def create_message(message_key_or_error, message_attributes = {})
        attributes =
          if message_key_or_error.is_a?(Import::Decorator::Error)
            error = message_key_or_error
            {
              criticity: (error.criticity || :error),
              message_key: error.message_key,
              message_attributes: error.message_attributes
            }
          else
            message_key = message_key_or_error
            {
              criticity: :error,
              message_key: message_key,
              message_attributes: message_attributes
            }
          end

        import_resource.messages.build attributes
        import_resource.status = attributes[:criticity].upcase
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
      delegate :stop_area_provider, :stop_area_referential, to: :import

      def synchronization
        Chouette::Sync::Referential.new(target).tap do |sync|
          sync.synchronize_with Chouette::Sync::StopArea::Netex
          sync.synchronize_with Chouette::Sync::Entrance::Netex
          sync.synchronize_with Chouette::Sync::StopAreaGroup::Netex

          sync.model_id_attribute = :objectid if import.override_internal_identifiers?
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
      delegate :line_provider, :line_referential, to: :import

      def synchronization
        @synchronization ||= Chouette::Sync::Referential.new(target).tap do |sync|
          sync.synchronize_with Chouette::Sync::Company::Netex
          sync.synchronize_with Chouette::Sync::Network::Netex
          sync.synchronize_with Chouette::Sync::LineNotice::Netex
          sync.synchronize_with Chouette::Sync::BookingArrangement::Netex
          sync.synchronize_with Chouette::Sync::Line::Netex

          sync.model_id_attribute = :objectid if import.override_internal_identifiers?
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
          .where(::Chouette::Network.quoted_table_name => { id: nil })
          .where.not(network_id: nil)
          .in_batches
          .update_all(network_id: nil)

        target
          .lines
          .left_joins(:company)
          .where(::Chouette::Company.quoted_table_name => { id: nil })
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

    class FareReferential < SynchronizedPart
      delegate :fare_provider, to: :import

      def synchronization
        Chouette::Sync::Referential.new(fare_provider).tap do |sync|
          sync.synchronize_with Chouette::Sync::FareZone::Netex
        end
      end

      def default_provider
        fare_provider
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

      attr_accessor :referential

      included do
        delegate :referential_inserter, to: :import
      end
    end

    class RouteJourneyPatterns < WithResourcePart
      include ReferentialPart
      delegate :netex_source, :scheduled_stop_points, :index_route_journey_patterns,
               :line_provider, :code_space, :lookup, :referential_lookup, to: :import

      def route_inserter
        @route_inserter ||= RouteInserter.new(
          referential_inserter, on_invalid: on_invalid, on_save: on_save
        )
      end

      def on_save
        lambda do |model|
          case model
          when Chouette::Route
            model.stop_points.each do |stop_point|
              (stop_point.transient(:scheduled_stop_point) || []).each do |scheduled_stop_point|
                scheduled_stop_point.stop_point_ids << stop_point.id
              end
            end
          when Chouette::JourneyPattern
            cache_journey_pattern model
          end
        end
      end

      def on_invalid
        lambda do |model|
          case model
          when Chouette::Route
            Rails.logger.debug do
              "Invalid Model: #{model.errors.inspect} #{model.journey_patterns.map(&:errors).inspect}"
            end
            create_message :route_invalid
          when Chouette::JourneyPattern
            Rails.logger.debug { "Invalid JourneyPattern: #{model.errors.inspect}" }
            create_message :journey_pattern_invalid
          end
        end
      end

      def import!
        each_route_with_journey_patterns do |netex_route, netex_journey_patterns|
          decorator = decorate(
            netex_route,
            journey_patterns: netex_journey_patterns,
            route_points: route_points,
            directions: directions,
            destination_displays: destination_displays
          )

          unless decorator.valid?
            hacked_decorator = decorate(
              netex_route,
              HackedOrderDecorator,
              journey_patterns: netex_journey_patterns,
              route_points: route_points,
              directions: directions,
              destination_displays: destination_displays
            )
            if hacked_decorator.enabled?
              Rails.logger.info "HackedOrderDecorator enabled for Route #{netex_route.id}"
              decorator = hacked_decorator
            end
          end

          unless decorator.valid?
            decorator.errors.each { |error| create_message error }
            Rails.logger.debug { "Errors found by Decorator for #{netex_route.inspect}: #{decorator.errors.inspect}" }

            next
          end

          if opposite_route_code = netex_route.inverse_route_ref&.ref
            cache_inverted_route netex_route.id, opposite_route_code
          end

          decorator.chouette_models.each do |chouette_route|
            route_inserter.insert chouette_route # rubocop:disable Rails/SkipsModelValidations
          end
        end

        referential_inserter.flush

        save_inverted_routes
      end

      def cache_journey_pattern(journey_pattern)
        index_route_journey_patterns[journey_pattern.registration_number] = {
          journey_pattern_id: journey_pattern.id,
          route_id: journey_pattern.route_id,
          stop_point_ids: journey_pattern.journey_pattern_stop_points.map(&:stop_point_id)
        }
      end

      def cache_inverted_route(route_id, inverted_route_ref)
        cached_inverted_routes[route_id] = inverted_route_ref
      end

      def cached_inverted_routes
        @cached_inverted_routes ||= {}
      end

      def each_route_with_journey_patterns(&block)
        netex_source.routes.each do |route|
          journey_patterns = netex_source.journey_patterns.find_by(route_ref: route.id)
          block.call route, journey_patterns
        end
      end

      def save_inverted_routes
        cached_inverted_routes.each do |code, opposite_route_code|
          route = referential_lookup.routes.find(code)
          if opposite_route_id = referential_lookup.routes.find_id(opposite_route_code)
            route.update(opposite_route_id: opposite_route_id)
          else
            create_message :inverted_route_not_found, { route_code: code, opposite_route_code: opposite_route_code }
          end
        end
      end

      delegate :route_points, :directions, :destination_displays, to: :netex_source

      class HackedOrderDecorator < ResourceDecorator
        attr_accessor :journey_patterns, :route_points, :directions, :destination_displays

        def enabled?
          ## TODO Could test order presence
          points_in_sequence.empty? && !stop_points.empty?
        end

        def chouette_line
          line = lookup.lines.find(line_ref.ref) if lookup
          errors.add :line_not_found unless line

          line
        end

        def chouette_models
          [ chouette_model ]
        end

        def chouette_model
          return unless chouette_line

          @chouette_model ||= chouette_line.routes.build(route_attributes).tap do |chouette_route|
            chouette_route.journey_patterns = chouette_journey_patterns
          end
        end

        def route_attributes
          {
            name: chouette_name,
            wayback: wayback,
            published_name: direction_name,
            stop_points: stop_points
          }.merge(chouette_attributes)
        end

        def wayback
          if Chouette::Route.wayback.values.include?(direction_type)
            direction_type
          else
            # Should be a warning
            # errors.add :direction_type_not_found
            :outbound
          end
        end

        def direction
          direction_id = direction_ref&.ref
          return unless direction_id

          direction = directions.find direction_id
          errors.add :direction_not_found unless direction

          direction
        end

        def direction_name
          direction&.name
        end

        def stop_points
          @stop_points ||= compute_stop_points
        end

        def stop_point(order:)
          stop_points.find { |s| s.position == order }
        end

        def for_boarding_for_alighting(raw_value, default: "normal")
          return default if raw_value.blank?
          raw_value == 'true' ? 'normal' : 'forbidden'
        end

        def compute_stop_points
          stop_points = []

          journey_patterns.each do |netex_journey_pattern|
            netex_journey_pattern.points_in_sequence.each do |stop_point_in_journey_pattern|
              order = stop_point_in_journey_pattern.order.to_i

              scheduled_stop_point_ref = stop_point_in_journey_pattern.scheduled_stop_point_ref&.ref
              scheduled_stop_point = scheduled_stop_points[scheduled_stop_point_ref]

              stop_point_attributes = {
                'stop_area_id' => scheduled_stop_point.stop_area_id,
                'position' => order,
                'for_boarding' => for_boarding_for_alighting(stop_point_in_journey_pattern.for_boarding),
                'for_alighting' => for_boarding_for_alighting(stop_point_in_journey_pattern.for_alighting),
                'flexible' => scheduled_stop_point.flexible
              }

              if existing_stop_point = stop_points[order]
                unless existing_stop_point.attributes >= stop_point_attributes
                  Rails.logger.debug "Invalid StopPoint: #{[existing_stop_point.attributes, stop_point_attributes].inspect}"
                  errors.add :invalid_stop_point_in_journey_pattern
                  return []
                end

                existing_stop_point.transient(:scheduled_stop_point) << scheduled_stop_point
              else
                stop_point = Chouette::StopPoint.new(stop_point_attributes).with_transient(scheduled_stop_point: [scheduled_stop_point])
                stop_points[order] = stop_point
              end
            end
          end

          stop_points.compact!

          stop_points
        end

        def chouette_journey_patterns
          @chouette_journey_patterns ||= journey_patterns.map do |netex_journey_pattern|
            decorate(
              netex_journey_pattern,
              JourneyPatternDecorator,
              route_decorator: self
            ).chouette_model
          end
        end

        class JourneyPatternDecorator < ResourceDecorator
          attr_accessor :route_decorator

          delegate :destination_displays, :lookup, :stop_point, to: :route_decorator

          def chouette_model
            @chouette_model ||= Chouette::JourneyPattern.new journey_pattern_attributes
          end

          def journey_pattern_attributes
            {
              # TODO: We should not use the JourneyPattern#registration_number
              registration_number: id,
              name: chouette_name,
              published_name: published_name,
              journey_pattern_stop_points: journey_pattern_stop_points,
              booking_arrangement_id: booking_arrangement_id
            }.merge(chouette_attributes)
          end

          def booking_arrangement_id
            netex_booking_arrangement_id = booking_arrangements&.first&.ref
            lookup.booking_arrangements.find_id netex_booking_arrangement_id
          end

          def published_name
            destination_display&.front_text
          end

          def destination_display
            destination_displays.find(destination_display_ref&.ref)
          end

          def journey_pattern_stop_points
            points_in_sequence.map do |stop_point_in_journey_pattern|
              stop_point = stop_point(order: stop_point_in_journey_pattern.order.to_i)
              Chouette::JourneyPatternStopPoint.new stop_point: stop_point
            end
          end
        end
      end

      class Decorator < ResourceDecorator
        attr_accessor :journey_patterns, :route_points, :directions, :destination_displays

        def validate
          stop_sequence

          super
        end

        def chouette_line
          return @chouette_line if @chouette_line

          line = lookup.lines.find(line_ref.ref) if lookup
          errors.add :line_not_found unless line

          @chouette_line = line
        end

        def chouette_models
          return [] unless chouette_line && clusterized_stops

          many_routes = clusterized_stops.many?
          @chouette_models ||= clusterized_stops.map do |stops_cluster|
            decorate(
              __getobj__,
              RouteDecorator,
              lookup: lookup,
              stops_cluster: stops_cluster,
              chouette_line: chouette_line,
              directions: directions,
              destination_displays: destination_displays,
              many_routes: many_routes
            ).chouette_model
          end
        end
        alias chouette_model chouette_models # so that #validate works

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
            # TODO Should be warning for the moment, see CHOUETTE-5282
            # errors.add :route_point_not_found
            return nil
          end

          route_point.projections.first&.project_to_point_ref&.ref
        end

        def sequence_merger
          return @sequence_merger if defined?(@sequence_merger)

          @sequence_merger = build_sequence_merger
        end

        def build_sequence_merger
          return unless netex_journey_pattern_ordered_points

          Sequence::Merger.new.tap do |merger|
            netex_journey_pattern_ordered_points.each do |_, jp_points|
              merger << jp_points.map { |jp_point| jp_point[:stop_area_id] }
            end

            route_stop_area_ids = route_scheduled_point_refs.map do |route_scheduled_point_ref|
              scheduled_stop_points[route_scheduled_point_ref].stop_area_id
            end
            merger << route_stop_area_ids if route_stop_area_ids.any?
          end
        end

        def stop_sequence
          return @stop_sequence if defined?(@stop_sequence)
          return nil unless sequence_merger

          stop_sequence = sequence_merger.merge
          unless stop_sequence
            errors.add :cannot_compute_stop_sequence, message_attributes: { route_id: id }
            return nil
          end

          @stop_sequence = stop_sequence
        end

        def sequence_cluster
          return @sequence_cluster if defined?(@sequence_cluster)
          return nil unless stop_sequence

          @sequence_cluster ||= Sequence::Cluster.new(stop_sequence).tap do |cluster|
            netex_journey_pattern_ordered_points.each do |netex_journey_pattern, jp_points|
              pattern = Sequence::Cluster::Pattern.new(netex_journey_pattern)

              jp_points.each do |jp_point|
                pattern.step(
                  jp_point[:stop_area_id],
                  flexible: jp_point[:scheduled_stop_point].flexible,
                  for_boarding: jp_point[:stop_point_in_journey_pattern].for_boarding || 'true',
                  for_alighting: jp_point[:stop_point_in_journey_pattern].for_alighting || 'true'
                ) do |step|
                  step.transient(:scheduled_stop_point, jp_point[:scheduled_stop_point])
                end
              end
              cluster.patterns << pattern
            end
          end
        end

        def clusterized_stops
          return @clusterized_stops if defined?(@clusterized_stops)
          return nil unless sequence_cluster

          @clusterized_stops = sequence_cluster.clusterize
        end

        def netex_journey_pattern_ordered_points
          return @netex_journey_pattern_ordered_points if defined?(@netex_journey_pattern_ordered_points)

          @netex_journey_pattern_ordered_points = nil
          @netex_journey_pattern_ordered_points = journey_patterns.map do |netex_journey_pattern|
            [
              netex_journey_pattern,
              netex_journey_pattern.points_in_sequence.sort_by { |sp| sp.order.to_i }.map do |sp_in_jp|
                scheduled_stop_point_id = sp_in_jp.scheduled_stop_point_ref&.ref
                scheduled_stop_point = scheduled_stop_points[scheduled_stop_point_id]
                # TODO: Message for CHOUETTE-4895
                # If stop_area_id is missing, the Route / Journey Patterns import is not possible
                stop_area_id = scheduled_stop_point&.stop_area_id

                unless stop_area_id
                  errors.add :stop_area_not_found_in_scheduled_stop_points
                  return nil
                end

                {
                  stop_point_in_journey_pattern: sp_in_jp,
                  scheduled_stop_point: scheduled_stop_point,
                  stop_area_id: stop_area_id
                }
              end
            ]
          end
        end
      end

      class RouteDecorator < ResourceDecorator
        attr_accessor :routes_decorator,
                      :stops_cluster,
                      :chouette_line,
                      :directions,
                      :destination_displays,
                      :many_routes

        def chouette_model
          @chouette_model ||= chouette_line.routes.build(route_attributes)
        end

        def route_attributes
          {
            name: chouette_name,
            wayback: wayback,
            published_name: direction_name,
            stop_points: stop_points,
            journey_patterns: journey_patterns
          }.merge(chouette_attributes).tap do |attrs|
            attrs.delete(:objectid) if many_routes
          end
        end

        def wayback
          if Chouette::Route.wayback.values.include?(direction_type)
            direction_type
          else
            # Should be a warning
            # errors.add :direction_type_not_found
            :outbound
          end
        end

        def direction
          direction_id = direction_ref&.ref
          return unless direction_id

          direction = directions.find direction_id
          errors.add :direction_not_found unless direction

          direction
        end

        def direction_name
          direction&.name
        end

        def stop_points
          @stop_points ||= stops_cluster.steps.map.with_index do |step, index|
            Chouette::StopPoint.new(
              stop_area_id: step.object,
              position: index,
              flexible: step.attributes[:flexible] || false,
              for_boarding: convert_for_boarding_and_for_alighting(step.attributes[:for_boarding]),
              for_alighting: convert_for_boarding_and_for_alighting(step.attributes[:for_alighting])
            ).with_transient(step.transients.merge(sequence_cluster_step: step))
          end
        end

        def stop_points_by_sequence_cluster_step
          @stop_points_by_sequence_cluster_step ||= stop_points.index_by { |sp| sp.transient(:sequence_cluster_step) }
        end

        def journey_patterns
          @journey_patterns ||= stops_cluster.patterns.map do |netex_journey_pattern, steps|
            decorate(
              netex_journey_pattern,
              JourneyPatternDecorator,
              route_decorator: self,
              sequence_cluster_steps: steps
            ).chouette_model
          end
        end

        def convert_for_boarding_and_for_alighting(value)
          return :forbidden if value == 'false'

          :normal
        end
      end

      class JourneyPatternDecorator < ResourceDecorator
        attr_accessor :route_decorator, :sequence_cluster_steps

        delegate :destination_displays, :lookup, to: :route_decorator

        def chouette_model
          @chouette_model ||= Chouette::JourneyPattern.new journey_pattern_attributes
        end

        def journey_pattern_attributes
          {
            # TODO: We should not use the JourneyPattern#registration_number
            registration_number: id,
            name: chouette_name,
            published_name: published_name,
            journey_pattern_stop_points: journey_pattern_stop_points,
            booking_arrangement_id: booking_arrangement_id
          }.merge(chouette_attributes)
        end

        def booking_arrangement_id
          netex_booking_arrangement_id = booking_arrangements&.first&.ref
          lookup.booking_arrangements.find_id netex_booking_arrangement_id if netex_booking_arrangement_id
        end

        def published_name
          destination_display&.front_text
        end

        def destination_display
          destination_displays.find(destination_display_ref&.ref)
        end

        def journey_pattern_stop_points
          sequence_cluster_steps.map do |sequence_cluster_step|
            Chouette::JourneyPatternStopPoint.new(
              stop_point: route_decorator.stop_points_by_sequence_cluster_step[sequence_cluster_step]
            )
          end
        end
      end
    end

    class TimeTables < WithResourcePart
      include ReferentialPart

      delegate :netex_source, :index_time_tables, to: :import

      def import!
        each_day_type_with_assignements_and_periods do |day_type, day_type_assignments, operating_periods|
          decorator = decorate(
            day_type,
            day_type_assignments: day_type_assignments,
            raw_operating_periods: operating_periods
          )

          unless decorator.valid?
            decorator.errors.each { |error| create_message error }
            Rails.logger.debug do
              "Errors found by Decorator for #{[day_type, day_type_assignments,
                                                operating_periods].inspect}: #{decorator.errors.inspect}"
            end

            next
          end

          time_table = decorator.chouette_model
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
          time_table_date.time_table = time_table
          referential_inserter.time_table_dates << time_table_date
        end

        time_table.periods.each do |time_table_period|
          time_table_period.time_table = time_table
          referential_inserter.time_table_periods << time_table_period
        end

        time_table.codes.each do |code|
          code.resource = time_table
          referential_inserter.codes << code
        end
      end

      class Decorator < ResourceDecorator
        attr_accessor :day_type_assignments, :raw_operating_periods

        def operating_periods
          raw_operating_periods.reject { |o| o.respond_to? :valid_day_bits }
        end

        def uic_operating_periods
          raw_operating_periods.select { |o| o.respond_to? :valid_day_bits }
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

        def chouette_model
          @chouette_model ||= Chouette::TimeTable.new(time_table_attributes).apply(memory_timetable)
        end

        def time_table_attributes
          {
            comment: chouette_name
          }.merge(chouette_attributes)
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

    def index_footnotes
      @index_footnotes ||= {}
    end

    class ReferentialNotices < WithResourcePart
      include ReferentialPart

      delegate :netex_source, :index_footnotes, to: :import

      def import!
        each_service_journey_notice do |notice|
          decorator = decorate(notice)

          unless decorator.valid?
            decorator.errors.each { |error| create_message error }
            Rails.logger.debug { "Errors found by Decorator for #{notice.inspect}: #{decorator.errors.inspect}" }

            next
          end

          footnote = decorator.chouette_model
          unless footnote&.valid?(:inserter)
            Rails.logger.debug { "Invalid Footnote: #{footnote.errors.inspect}" }
            next
          end

          save(footnote)

          index_footnotes[notice.id] = footnote.id
        end

        referential_inserter.flush
      end

      def each_service_journey_notice
        netex_source.notices.each do |notice|
          next unless notice.type_of_notice_ref&.ref == 'ServiceJourneyNotice'

          yield notice
        end
      end

      def save(footnote)
        referential_inserter.footnotes << footnote

        footnote.codes.each do |code|
          code.resource = footnote
          referential_inserter.codes << code
        end
      end

      class Decorator < ResourceDecorator
        def chouette_model
          @chouette_model ||= Chouette::Footnote.new(footnote_attributes)
        end

        def footnote_attributes
          {
            code: public_code,
            label: text,
            codes: codes
          }.merge(chouette_attributes)
        end
      end
    end

    class VehicleJourneys < WithResourcePart
      include ReferentialPart
      delegate :netex_source, :index_route_journey_patterns, :index_time_tables, :index_footnotes, :lookup, to: :import

      def import!
        netex_source.service_journeys.each do |service_journey|
          decorator = decorate(
            service_journey,
            index_route_journey_patterns: index_route_journey_patterns,
            index_time_tables: index_time_tables,
            index_footnotes: index_footnotes
          )

          unless decorator.valid?
            decorator.errors.each { |error| create_message error }
            Rails.logger.debug do
              "Errors found by Decorator for #{service_journey.inspect}: #{decorator.errors.inspect}"
            end

            next
          end

          vehicle_journey_inserter.insert decorator.chouette_model # rubocop:disable Rails/SkipsModelValidations
        end

        referential_inserter.flush
      end

      def vehicle_journey_inserter
        @vehicle_journey_inserter ||= VehicleJourneyInserter.new(referential_inserter, on_invalid: on_invalid)
      end

      def on_invalid
        lambda do |vehicle_journey|
          Rails.logger.info { "Invalid Vehicle Journey: #{vehicle_journey.errors.inspect}" }
          create_message :vehicle_journey_invalid
        end
      end

      class Decorator < ResourceDecorator
        attr_accessor :index_route_journey_patterns, :index_time_tables, :index_footnotes

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

        def line_notice_ids
          manage_netex_notice_assignments
          @line_notice_ids
        end

        def vehicle_journey_footnote_relationships
          manage_netex_notice_assignments
          @vehicle_journey_footnote_relationships
        end

        def manage_netex_notice_assignments
          return if @line_notice_ids && @vehicle_journey_footnote_relationships

          line_notice_ids = []
          vehicle_journey_footnote_relationships = []
          notice_refs.each do |notice_ref|
            ref = notice_ref.ref
            next unless ref

            footnote_id = index_footnotes[ref]
            if footnote_id
              vehicle_journey_footnote_relationships << Chouette::VehicleJourneyFootnoteRelationship.new(
                footnote_id: footnote_id
              )
            else
              line_notice = lookup.line_notices.find(ref) if lookup
              if line_notice
                line_notice_ids << line_notice.id
              else
                errors.add :notice_not_found
              end
            end
          end

          @line_notice_ids = line_notice_ids
          @vehicle_journey_footnote_relationships = vehicle_journey_footnote_relationships
        end

        def published_journey_identifier
          public_code || id
        end

        def vehicle_journey_attributes
          {
            route_id: route_id,
            journey_pattern_id: journey_pattern_id,
            published_journey_name: name,
            line_notice_ids: line_notice_ids,
            published_journey_identifier: published_journey_identifier,
            vehicle_journey_at_stops: vehicle_journey_at_stops,
            vehicle_journey_time_table_relationships: vehicle_journey_time_table_relationships,
            vehicle_journey_footnote_relationships: vehicle_journey_footnote_relationships
          }.merge(chouette_attributes)
        end

        def chouette_model
          @chouette_model ||= Chouette::VehicleJourney.new vehicle_journey_attributes
        end

        def chouette_stop_point_ids
          @chouette_stop_point_ids ||= route_journey_pattern(:stop_point_ids) || []
        end

        def vehicle_journey_at_stops
          unless chouette_stop_point_ids.count == passing_times.count
            errors << :number_passing_times_incoherent
            return []
          end

          [].tap do |vehicle_journey_at_stops|
            chouette_stop_point_ids.each_with_index do |stop_point_id, index|
              decorated_passing_time = PassingTimeDecorator.new(passing_times[index], stop_point_id: stop_point_id, first: index.zero?)
              # TODO See CHOUETTE-4895
              # unless decorated_passing_time.valid?
              #   errors << :passing_time_without_departure_time
              #   return []
              # end

              vehicle_journey_at_stops << decorated_passing_time.chouette_model
            end
          end
        end

        class PassingTimeDecorator < SimpleDelegator
          def initialize(passing_time, stop_point_id: nil, first: false)
            super(passing_time)
            @stop_point_id = stop_point_id
            @first = first
          end
          attr_reader :stop_point_id

          def first?
            @first
          end

          def valid?
            true
          end

          def arrival_time_of_day
            if arrival_time
              time_of_day arrival_time, arrival_day_offset
            else
              departure_time_of_day
            end
          end

          def departure_time_of_day
            time_of_day departure_time, departure_day_offset
          end

          def latest_arrival_time_of_day
            time_of_day(latest_arrival_time, latest_arrival_day_offset)&.second_offset
          end

          def earliest_departure_time_of_day
            time_of_day(earliest_departure_time, earliest_departure_day_offset)&.second_offset
          end

          def chouette_model
            return unless valid?

            Chouette::VehicleJourneyAtStop.new(
              stop_point_id: stop_point_id,
              arrival_time_of_day: arrival_time_of_day,
              departure_time_of_day: departure_time_of_day,
              latest_arrival_time_of_day: latest_arrival_time_of_day,
              earliest_departure_time_of_day: earliest_departure_time_of_day
            )
          end

          private

          def time_of_day(time, day_offset)
            return if time.blank?

            TimeOfDay.parse(time, day_offset: day_offset)
          end
        end

        def vehicle_journey_time_table_relationships
          @vehicle_journey_time_table_relationships ||= [].tap do |vehicle_journey_time_tables|
            day_types.map do |day_type|
              time_table_id = index_time_tables[day_type.ref]
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

    class VehicleJourneyStopAssignments < WithResourcePart
      include ReferentialPart

      delegate :netex_source, :scheduled_stop_points, :lookup, to: :import

      def import!
        netex_source.vehicle_journey_stop_assignments.each do |stop_assignment|
          decorated_assignment = decorate(stop_assignment, referential: referential)

          unless decorated_assignment.valid?
            Rails.logger.info { "Invalid VehicleJourneyStopAssignment: #{decorated_assignment.inspect} "}
            create_message :ancestor_associated_route_not_found

            next
          end

          decorated_assignment.vehicle_journey_at_stops.find_each do |vehicle_journey_at_stop|
            vehicle_journey_at_stop.update stop_area_id: decorated_assignment.stop_area.id
          end
        end
      end

      class Decorator < ResourceDecorator
        attr_accessor :referential

        def stop_area_code
          (quay_ref || stop_splace_ref)&.ref
        end

        def stop_area
          lookup.stop_areas.find(stop_area_code)
        end

        def scheduled_stop_point
          return unless scheduled_stop_point_ref

          @scheduled_stop_point ||= scheduled_stop_points[scheduled_stop_point_ref.ref]
        end

        def scheduled_stop_point_stop_area
          lookup.stop_areas.find_by_id(scheduled_stop_point&.stop_area_id) # rubocop:disable Rails/DynamicFindBy
        end

        def valid?
          scheduled_stop_point.present? && stop_area.present?
        end

        def vehicle_journey_codes
          vehicle_journey_refs.map(&:ref)
        end

        def vehicle_journey_at_stops
          referential.vehicle_journey_at_stops.joins(:vehicle_journey)
            .merge(referential.vehicle_journeys.by_code(code_space, vehicle_journey_codes))
            .where(stop_point_id: scheduled_stop_point.stop_point_ids)
        end

        def manage_netex_notice_assignments
          return if @line_notice_ids && @vehicle_journey_footnote_relationships

          line_notice_ids = []
          vehicle_journey_footnote_relationships = []
          notice_refs.each do |notice_ref|
            ref = notice_ref.ref
            next unless ref

            footnote_id = index_footnotes[ref]
            if footnote_id
              vehicle_journey_footnote_relationships << Chouette::VehicleJourneyFootnoteRelationship.new(
                footnote_id: footnote_id
              )
            else
              line_notice = lookup.line_notices.find(ref) if lookup
              if line_notice
                line_notice_ids << line_notice.id
              else
                errors.add :notice_not_found
              end
            end
          end

          @line_notice_ids = line_notice_ids
          @vehicle_journey_footnote_relationships = vehicle_journey_footnote_relationships
        end
      end
    end

    def scheduled_stop_points
      @scheduled_stop_points ||= {}
    end

    class ScheduledStopPoint
      def initialize(id:, stop_area_id:, flexible: false)
        @id = id
        @stop_area_id = stop_area_id
        @flexible = flexible
      end

      def stop_point_ids
        @stop_point_ids ||= []
      end

      attr_accessor :id, :stop_area_id, :flexible
    end

    class ScheduledStopPoints < WithResourcePart
      delegate :netex_source, :stop_area_provider, :scheduled_stop_points, :lookup, to: :import

      def import!
        %i[passenger_stop_assignments flexible_stop_assignments].each do |assignment_type|
          netex_source.send(assignment_type).each do |stop_assignment|
            scheduled_stop_point_id = stop_assignment.scheduled_stop_point_ref&.ref
            stop_area_code = find_stop_area_code(stop_assignment)

            unless stop_area_code
              create_message :stop_area_code_empty
              next
            end

            if (stop_area_id = lookup.stop_areas.find_id(stop_area_code))
              scheduled_stop_point = ScheduledStopPoint.new(
                id: scheduled_stop_point_id,
                stop_area_id: stop_area_id,
                flexible: flexible?(stop_assignment)
              )
              scheduled_stop_points[scheduled_stop_point.id] = scheduled_stop_point
            else
              create_message :stop_area_not_found, code: stop_area_code
              next
            end
          end
        end
      end

      private

      def find_stop_area_code(stop_assignment)
        return stop_assignment.flexible_stop_place_ref&.ref if flexible?(stop_assignment)

        stop_assignment.quay_ref&.ref || stop_assignment.stop_place_ref&.ref
      end

      def flexible?(stop_assignment)
        stop_assignment.is_a?(::Netex::FlexibleStopAssignment)
      end
    end

    class RoutingConstraintZones < WithResourcePart
      delegate :netex_source, :code_space, :scheduled_stop_points, :line_provider,
               :stop_area_provider, :event_handler, to: :import

      def import!
        netex_source.routing_constraint_zones.each do |zone|
          decorator = decorate(zone)

          unless decorator.valid?
            create_message :invalid_netex_source_routing_constraint_zone
            next
          end

          line_routing_constraint_zone = decorator.chouette_model

          # TODO: share error creating from model errors
          unless line_routing_constraint_zone.valid?
            line_routing_constraint_zone.errors.messages.each_key do |attribute|
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

      class Decorator < ResourceDecorator
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

        def chouette_model
          # TODO: CHOUETTE-3346 this seems untested
          @chouette_model ||= line_provider.line_routing_constraint_zones
                                           .first_or_initialize_by_code(code_space, code_value) do |zone|
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
        source.transformers << ::Netex::Transformer::FakeArrivalDayOffset.new
        source.transformers << ::Netex::Transformer::DefinePublicCodeFromTrainNumber.new

        source.read(local_file.path, type: file_extension)
      end
    end

    def line_ids
      []
    end
  end
end
