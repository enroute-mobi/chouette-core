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

      DEFAULT_NAME = 'Default'

      attr_accessor :code_builder, :scheduled_stop_points,
                    :override_internal_identifiers,
                    :line_provider, :stop_area_provider # TODO: waiting for lookup whole integration

      alias override_internal_identifiers? override_internal_identifiers

      def default_name
        DEFAULT_NAME
      end

      def chouette_name
        name || default_name
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
        import_resource.save!
      end

      # TODO: manage a given NeTEx resource to save tags
      def create_message(message_key_or_error, message_attributes = {})
        attributes =
          if message_key_or_error.is_a?(Import::Decorator::Error)
            error = message_key_or_error
            {
              criticity: (error.criticity || :error),
              message_key: error.message_key,
              message_attributes: error.message_attributes,
              resource_attributes: error.resource.tags.transform_keys do |k|
                case k
                when :line
                  'line_number'
                when :column
                  'column_number'
                else
                  k.to_s
                end
              end
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

      def add_resource_error(netex_resource, message_key, **attributes)
        create_message(Import::Decorator::Error.new(message_key, resource: netex_resource, **attributes))
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
        return unless default_provider

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
        return unless default_provider

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

        config.add LegacyObjectidLoaderInserter
        config.add ObjectidInserter

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

          valid = decorator.valid?
          unless valid
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
              valid = decorator.valid?
            end
          end

          unless valid
            decorator.errors.each { |error| create_message error }
            Rails.logger.debug { "Errors found by Decorator for #{netex_route.inspect}: #{decorator.errors.inspect}" }

            next
          end
          decorator.journey_pattern_errors.each { |error| create_message error }

          if opposite_route_code = netex_route.inverse_route_ref&.ref
            cache_inverted_route netex_route.id, opposite_route_code
          end

          decorator.chouette_models.each do |chouette_route|
            route_inserter.insert chouette_route # rubocop:disable Rails/SkipsModelValidations
          end
        end

        referential_inserter.flush

        save_inverted_routes

        detect_orphan_journey_patterns
      end

      def cache_journey_pattern(journey_pattern)
        index_route_journey_patterns[journey_pattern.transient(:netex_id)] = {
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

      def detect_orphan_journey_patterns
        netex_source.journey_patterns.each do |netex_journey_pattern|
          route_ref = netex_journey_pattern.route_ref&.ref
          unless route_ref.present?
            add_resource_error(netex_journey_pattern, :journey_pattern_without_route_ref)
            next
          end

          unless netex_source.routes.find(route_ref)
            add_resource_error(
              netex_journey_pattern,
              :journey_pattern_with_unknown_route_ref,
              message_attributes: { route_id: route_ref }
            )
            next
          end
        end
      end

      delegate :route_points, :directions, :destination_displays, to: :netex_source

      module RouteJourneyPatternErrorsSupport
        def journey_pattern_errors
          @journey_pattern_errors ||= []
        end

        def add_journey_pattern_error(netex_journey_pattern, message_key, **attributes)
          journey_pattern_errors << Import::Decorator::Error.new(
            message_key,
            resource: netex_journey_pattern,
            **attributes
          )
        end
      end

      module RouteDecoratorSupport
        include RouteJourneyPatternErrorsSupport

        def validate
          super
          errors.add :route_without_id unless id.present?
        end

        def default_name
          case direction_type
          when *::Chouette::Route.wayback.values
            direction_type.capitalize
          else
            super
          end
        end

        def chouette_line
          return @chouette_line if defined?(@chouette_line)

          if line_ref&.ref
            line = lookup.lines.find(line_ref.ref) if lookup
            errors.add :route_with_line_unknown, message_attributes: { line_ref: line_ref.ref } unless line
          else
            errors.add :route_with_line_ref_undefined
          end

          @chouette_line = line
        end

        def wayback
          if direction_type.blank?
            :outbound
          elsif Chouette::Route.wayback.values.include?(direction_type)
            direction_type
          else
            errors.add :route_with_direction_type_unsupported, message_attributes: { direction_type: direction_type }
            nil
          end
        end

        def direction
          direction_id = direction_ref&.ref
          return unless direction_id

          direction = directions.find direction_id
          errors.add :route_with_direction_unknown, message_attributes: { direction_id: direction_id } unless direction

          direction
        end

        def direction_name
          direction&.name
        end

        def stop_point_in_journey_pattern_scheduled_stop_point(netex_journey_pattern, stop_point_in_journey_pattern)
          scheduled_stop_point_ref = stop_point_in_journey_pattern.scheduled_stop_point_ref&.ref
          unless scheduled_stop_point_ref
            add_journey_pattern_error(
              netex_journey_pattern,
              :journey_pattern_without_scheduled_stop_point,
              resource: stop_point_in_journey_pattern,
              message_attributes: { journey_pattern_id: netex_journey_pattern.id }
            )
            return nil
          end

          scheduled_stop_point = scheduled_stop_points[scheduled_stop_point_ref]
          unless scheduled_stop_point
            add_journey_pattern_error(
              netex_journey_pattern,
              :journey_pattern_unknown_scheduled_stop_point,
              resource: stop_point_in_journey_pattern,
              message_attributes: { journey_pattern_id: netex_journey_pattern.id }
            )
            return nil
          end

          scheduled_stop_point
        end
      end

      module RouteWithJourneyPatternDecoratorsSupport
        include RouteJourneyPatternErrorsSupport

        def validate
          super
          journey_pattern_decorators.each do |journey_pattern_decorator|
            journey_pattern_decorator.valid?
            journey_pattern_errors.concat(journey_pattern_decorator.errors)
          end
        end

        def journey_pattern_decorators
          raise NotImplementedError
        end

        def chouette_journey_patterns
          @chouette_journey_patterns ||= journey_pattern_decorators.map(&:chouette_model)
        end
      end

      class AbstractJourneyPatternDecorator < ResourceDecorator
        attr_accessor :route_decorator

        delegate :destination_displays, :lookup, to: :route_decorator

        def validate
          super

          errors.add :journey_pattern_without_id unless id.present?

          errors.add :journey_pattern_less_than_2_stop_points unless journey_pattern_stop_points.many?
        end

        def chouette_model
          @chouette_model ||= Chouette::JourneyPattern.new(journey_pattern_attributes).with_transient(netex_id: id)
        end

        def journey_pattern_attributes
          {
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
          raise NotImplementedError
        end
      end

      class HackedOrderDecorator < ResourceDecorator
        include RouteDecoratorSupport
        include RouteWithJourneyPatternDecoratorsSupport

        attr_accessor :journey_patterns, :route_points, :directions, :destination_displays

        def enabled?
          ## TODO Could test order presence
          points_in_sequence.empty? && !stop_points.empty?
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

              scheduled_stop_point = stop_point_in_journey_pattern_scheduled_stop_point(
                netex_journey_pattern, stop_point_in_journey_pattern
              )

              # TODO: Message for CHOUETTE-4895
              # If stop_area_id is missing, the Route / Journey Patterns import is not possible
              stop_area_id = scheduled_stop_point&.stop_area_id
              unless stop_area_id
                add_journey_pattern_error(netex_journey_pattern, :stop_area_not_found_in_scheduled_stop_points)
                break
              end

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

        def journey_pattern_decorators
          @journey_pattern_decorators ||= journey_patterns.map do |netex_journey_pattern|
            decorate(
              netex_journey_pattern,
              JourneyPatternDecorator,
              route_decorator: self
            )
          end
        end

        class JourneyPatternDecorator < AbstractJourneyPatternDecorator
          delegate :stop_point, to: :route_decorator

          def journey_pattern_stop_points
            @journey_pattern_stop_points ||= points_in_sequence.map do |stop_point_in_journey_pattern|
              stop_point = stop_point(order: stop_point_in_journey_pattern.order.to_i)
              Chouette::JourneyPatternStopPoint.new stop_point: stop_point
            end
          end
        end
      end

      class Decorator < ResourceDecorator
        include RouteDecoratorSupport

        attr_accessor :journey_patterns, :route_points, :directions, :destination_displays

        def validate
          super

          errors.add :route_without_journey_pattern unless journey_patterns.any?
        end

        def clusterized_decorators
          return [] unless chouette_line && clusterized_stops

          @clusterized_decorators ||= clusterized_stops.map.with_index do |stops_cluster, index|
            decorate(
              __getobj__,
              RouteDecorator,
              lookup: lookup,
              stops_cluster: stops_cluster,
              chouette_line: chouette_line,
              name: chouette_name,
              wayback: wayback,
              published_name: direction_name,
              destination_displays: destination_displays,
              index: index
            )
          end
        end

        def valid?
          result = super
          clusterized_decorators.each do |route|
            result &= route.valid?
            errors.concat(route.errors)
            journey_pattern_errors.concat(route.journey_pattern_errors)
          end
          result
        end

        def chouette_models
          @chouette_models ||= clusterized_decorators.map(&:chouette_model)
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
          @sequence_merger ||= Sequence::Merger.new.tap do |merger|
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

          @stop_sequence = build_stop_sequence
        end

        def build_stop_sequence
          stop_sequence = sequence_merger.merge
          unless stop_sequence
            errors.add :cannot_compute_stop_sequence
            return nil
          end
          stop_sequence
        end

        def sequence_cluster
          return @sequence_cluster if defined?(@sequence_cluster)

          @sequence_cluster = build_sequence_cluster
        end

        def build_sequence_cluster
          return nil unless stop_sequence

          Sequence::Cluster.new(stop_sequence).tap do |cluster|
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

          @clusterized_stops = sequence_cluster&.clusterize
        end

        def netex_journey_pattern_ordered_points
          @netex_journey_pattern_ordered_points ||= journey_patterns.filter_map do |netex_journey_pattern|
            ordered_points = netex_journey_pattern.points_in_sequence.sort_by { |sp| sp.order.to_i }.map do |sp_in_jp|
              scheduled_stop_point = stop_point_in_journey_pattern_scheduled_stop_point(netex_journey_pattern, sp_in_jp)

              # if we do not find the scheduled stop point, the journey pattern is invalid, we break this loop and
              # continue with the next journey pattern
              break nil unless scheduled_stop_point

              {
                stop_point_in_journey_pattern: sp_in_jp,
                scheduled_stop_point: scheduled_stop_point,
                stop_area_id: scheduled_stop_point.stop_area_id
              }
            end

            # if some scheduled stop point is missing in this journey pattern, we continue with the next journey pattern
            next nil unless ordered_points

            [netex_journey_pattern, ordered_points]
          end
        end
      end

      class RouteDecorator < ResourceDecorator
        include RouteWithJourneyPatternDecoratorsSupport

        attr_accessor :routes_decorator,
                      :stops_cluster,
                      :chouette_line,
                      :name,
                      :wayback,
                      :published_name,
                      :destination_displays,
                      :index

        def chouette_model
          @chouette_model ||= chouette_line.routes.build(route_attributes)
        end

        def route_attributes
          {
            name: name,
            wayback: wayback,
            published_name: published_name,
            stop_points: stop_points,
            journey_patterns: chouette_journey_patterns
          }.merge(chouette_attributes).tap do |attrs|
            attrs.delete(:objectid) unless index.zero?
          end
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

        def journey_pattern_decorators
          @journey_pattern_decorators ||= stops_cluster.patterns.map do |netex_journey_pattern, steps|
            decorate(
              netex_journey_pattern,
              JourneyPatternDecorator,
              route_decorator: self,
              sequence_cluster_steps: steps
            )
          end
        end

        def convert_for_boarding_and_for_alighting(value)
          return :forbidden if value == 'false'

          :normal
        end
      end

      class JourneyPatternDecorator < AbstractJourneyPatternDecorator
        attr_accessor :sequence_cluster_steps

        def journey_pattern_stop_points
          @journey_pattern_stop_points ||= sequence_cluster_steps.map do |sequence_cluster_step|
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
        netex_source.day_types.each do |day_type|
          day_type_refs << day_type.id

          decorator = decorate(day_type, netex_source: netex_source)

          unless decorator.valid?
            decorator.errors.each { |error| create_message error }
            Rails.logger.debug do
              "Errors found by Decorator for #{day_type.inspect}: #{decorator.errors.inspect}"
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

        detect_orphan_day_type_assignments

        referential_inserter.flush
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

      def detect_orphan_day_type_assignments
        netex_source.day_type_assignments.each do |day_type_assignment|
          day_type_ref = day_type_assignment.day_type_ref&.ref
          next if day_type_ref && day_type_refs.include?(day_type_ref)

          add_resource_error(
            day_type_assignment,
            :day_type_assignment_unknown_day_type,
            message_attributes: { day_type_ref: day_type_ref }
          )
        end
      end

      def day_type_refs
        @day_type_refs ||= Set.new
      end

      class Decorator < ResourceDecorator
        attr_accessor :netex_source

        def day_type_assignments
          @day_type_assignments ||= netex_source.day_type_assignments.find_by(day_type_ref: id)
        end

        def partition_day_type_assignments
          return if @operating_periods && @uic_operating_periods && @included_dates && @excluded_dates

          @operating_periods = []
          @uic_operating_periods = []
          @included_dates = []
          @excluded_dates = []

          day_type_assignments.each do |day_type_assignment|
            date = day_type_assignment.date
            # TODO: date parse error

            if date
              if day_type_assignment.available?
                @included_dates << date
              else
                @excluded_dates << date
              end
            else
              operating_period_id = day_type_assignment.operating_period_ref&.ref
              if operating_period_id
                operating_period = netex_source.operating_periods.find(operating_period_id)
                unless operating_period
                  errors.add(
                    :day_type_assignment_unknown_operation_period,
                    resource: day_type_assignment,
                    message_attributes: { operating_period_id: operating_period_id }
                  )
                  next
                end

                if operating_period.respond_to?(:valid_day_bits)
                  @uic_operating_periods << operating_period
                else
                  @operating_periods << operating_period
                end
              else
                errors.add(:day_type_assignment_without_date_or_operation_period, resource: day_type_assignment)
              end
            end
          end
        end

        def operating_periods
          partition_day_type_assignments
          @operating_periods
        end

        def uic_operating_periods
          partition_day_type_assignments
          @uic_operating_periods
        end

        def included_dates
          partition_day_type_assignments
          @included_dates
        end

        def excluded_dates
          partition_day_type_assignments
          @excluded_dates
        end

        def days_of_week
          Cuckoo::Timetable::DaysOfWeek.new.tap do |days_of_week|
            %i[monday tuesday wednesday thursday friday saturday sunday].each do |day|
              days_of_week.enable day if send "#{day}?"
            end
          end
        end

        def timetable_periods
          operating_periods_chouette_models(operating_periods) do |operating_period|
            decorate(operating_period, OperatingPeriodDecorator, days_of_week: days_of_week)
          end
        end

        def uic_timetables
          operating_periods_chouette_models(uic_operating_periods) do |operating_period|
            decorate(operating_period, UicOperatingPeriodDecorator)
          end
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

        private

        def operating_periods_chouette_models(operation_periods)
          operation_periods.filter_map do |operating_period|
            decorator = yield operating_period
            unless decorator.valid?
              errors.concat(decorator.errors)
              next nil
            end

            decorator.chouette_model
          end
        end
      end

      class AbstractOperatingPeriodDecorator < ResourceDecorator
        def chouette_model
          unless from_date
            errors.add(:operating_period_without_from_date)
            return nil
          end

          unless to_date
            errors.add(:operating_period_without_to_date)
            return nil
          end

          chouette_model_without_validation
        end

        protected

        def chouette_model_without_validation
          raise NotImplementedError
        end
      end

      class OperatingPeriodDecorator < AbstractOperatingPeriodDecorator
        attr_accessor :days_of_week

        protected

        def chouette_model_without_validation
          Cuckoo::Timetable::Period.from(date_range, days_of_week)
        end
      end

      class UicOperatingPeriodDecorator < AbstractOperatingPeriodDecorator
        def chouette_model
          unless valid_day_bits
            errors.add(:uic_operating_period_without_valid_day_bits)
            return nil
          end

          super
        end

        protected

        def chouette_model_without_validation
          Cuckoo::DaysBit.new(
            from: date_range.min,
            bitset: Bitset.from_s(valid_day_bits)
          ).to_timetable
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

        def chouette_attributes
          super.except(:objectid)
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
          return @netex_journey_pattern_ref if defined?(@netex_journey_pattern_ref)

          @netex_journey_pattern_ref = build_netex_journey_pattern_ref
        end

        def build_netex_journey_pattern_ref
          netex_journey_pattern_ref = journey_pattern_ref&.ref
          unless netex_journey_pattern_ref
            errors.add(:service_journey_without_journey_pattern)
            return nil
          end

          netex_journey_pattern_ref
        end

        def route_journey_pattern(attribute)
          @route_journey_pattern ||= index_route_journey_patterns[netex_journey_pattern_ref]
          @route_journey_pattern[attribute] if @route_journey_pattern
        end

        def journey_pattern_id
          return @journey_pattern_id if defined?(@journey_pattern_id)

          journey_pattern_id = route_journey_pattern(:journey_pattern_id)
          unless journey_pattern_id
            errors.add(:journey_pattern_not_found, message_attributes: { journey_pattern_id: netex_journey_pattern_ref })
            return nil
          end

          @journey_pattern_id = journey_pattern_id
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

        def passing_time_decorators
          @passing_time_decorators ||= build_passing_time_decorators
        end

        def build_passing_time_decorators
          unless chouette_stop_point_ids.count == passing_times.count
            errors.add(
              :number_passing_times_incoherent,
              message_attributes: {
                passing_times_count: passing_times.count,
                stop_points_count: chouette_stop_point_ids.count
              }
            )
            return []
          end

          chouette_stop_point_ids.map.with_index do |stop_point_id, index|
            decorated_passing_time = decorate(
              passing_times[index],
              PassingTimeDecorator,
              netex_service_journey_id: id,
              stop_point_id: stop_point_id,
              first: index.zero?,
              last: index == chouette_stop_point_ids.count - 1
            )
            unless decorated_passing_time.valid?
              errors.concat(decorated_passing_time.errors)
              return []
            end

            decorated_passing_time
          end
        end

        def vehicle_journey_at_stops
          last_passing_time = nil

          passing_time_decorators.each do |pt|
            if pt.arrival_time_of_day && last_passing_time && pt.arrival_time_of_day < last_passing_time
              errors.add(:passing_times_non_chronological)
              return []
            end

            if pt.arrival_time_of_day && pt.departure_time_of_day && pt.arrival_time_of_day > pt.departure_time_of_day
              errors.add(:passing_times_non_chronological)
              return []
            end

            last_passing_time = pt.departure_time_of_day if pt.departure_time_of_day
          end

          passing_time_decorators.map(&:chouette_model)
        end

        class PassingTimeDecorator < ResourceDecorator
          attr_accessor :netex_service_journey_id, :stop_point_id, :first, :last

          def arrival_time_of_day
            return @arrival_time_of_day if defined?(@arrival_time_of_day)

            @arrival_time_of_day = if arrival_time
                                     time_of_day(arrival_time, arrival_day_offset)
                                   else
                                     departure_time_of_day
                                   end
          end

          def departure_time_of_day
            return @departure_time_of_day if defined?(@departure_time_of_day)

            @departure_time_of_day = time_of_day(departure_time, departure_day_offset)
          end

          def latest_arrival_time_of_day
            return @latest_arrival_time_of_day if defined?(@latest_arrival_time_of_day)

            @latest_arrival_time_of_day = time_of_day(latest_arrival_time, latest_arrival_day_offset)&.second_offset
          end

          def earliest_departure_time_of_day
            return @earliest_departure_time_of_day if defined?(@earliest_departure_time_of_day)

            @earliest_departure_time_of_day = time_of_day(earliest_departure_time, earliest_departure_day_offset)&.second_offset # rubocop:disable Layout/LineLength
          end

          def chouette_model
            return @chouette_model if @chouette_model

            arrival = arrival_time_of_day || latest_arrival_time_of_day
            if !first && arrival.nil?
              errors.add(
                :passing_time_without_arrival_time,
                message_attributes: { resource_id: netex_service_journey_id }
              )
            end

            departure = departure_time_of_day || earliest_departure_time_of_day
            if !last && departure.nil?
              errors.add(
                :passing_time_without_departure_time,
                message_attributes: { resource_id: netex_service_journey_id }
              )
            end

            if (arrival_time_of_day && earliest_departure_time_of_day) ||
                (departure_time_of_day && latest_arrival_time_of_day)
              errors.add(
                :passing_time_both_flexible_and_non_flexible,
                message_attributes: { resource_id: netex_service_journey_id }
              )
            end

            @chouette_model = Chouette::VehicleJourneyAtStop.new(
              stop_point_id: stop_point_id,
              arrival_time_of_day: arrival_time_of_day,
              departure_time_of_day: departure_time_of_day,
              latest_arrival_time_of_day: latest_arrival_time_of_day,
              earliest_departure_time_of_day: earliest_departure_time_of_day
            ).skipping_presence_of(:stop_point)
          end

          private

          def time_of_day(time, day_offset)
            return if time.blank?

            TimeOfDay.parse(time, day_offset: day_offset)
          end
        end

        def vehicle_journey_time_table_relationships
          unless day_types.any?
            errors.add(:service_journey_without_day_type)
            return []
          end

          @vehicle_journey_time_table_relationships ||= day_types.filter_map do |day_type|
            time_table_id = index_time_tables[day_type.ref]
            unless time_table_id
              errors.add(:time_table_not_found, message_attributes: { day_type_id: day_type.ref })
              next nil
            end

            Chouette::TimeTablesVehicleJourney.new(time_table_id: time_table_id).skipping_presence_of(:time_table)
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
            Rails.logger.info do
              "Invalid VehicleJourneyStopAssignment: #{decorated_assignment.inspect} scheduled_stop_point exists: #{decorated_assignment.scheduled_stop_point.present?}, stop_area exists: #{decorated_assignment.stop_area.present?}"
            end
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
        import_stop_assignemnts(netex_source.passenger_stop_assignments, PassengerStopAssignmentDecorator)
        import_stop_assignemnts(netex_source.flexible_stop_assignments, FlexibleStopAssignmentDecorator)
        detect_orphans
      end

      private

      def import_stop_assignemnts(stop_assignments, decorator_class)
        stop_assignments.each do |stop_assignment|
          decorator = decorate(stop_assignment, decorator_class)
          decorator.errors.each { |error| create_message(error) } unless decorator.valid?
        end
      end

      def detect_orphans
        netex_source.scheduled_stop_points.each do |scheduled_stop_point|
          next if scheduled_stop_points.key?(scheduled_stop_point.id)

          add_resource_error(scheduled_stop_point, :scheduled_stop_point_without_assignment)
        end
      end

      class StopAssignmentDecorator < ResourceDecorator
        def chouette_model
          return unless scheduled_stop_point

          if scheduled_stop_points.key?(scheduled_stop_point.id)
            errors.add(
              :scheduled_stop_point_alreay_associated,
              message_attributes: { scheduled_stop_point_id: scheduled_stop_point.id }
            )
            return
          end

          scheduled_stop_points[scheduled_stop_point.id] = scheduled_stop_point
        end

        def scheduled_stop_point
          return unless scheduled_stop_point_id && stop_area_id

          ScheduledStopPoint.new(
            id: scheduled_stop_point_id,
            stop_area_id: stop_area_id,
            flexible: flexible?
          )
        end

        def scheduled_stop_point_id
          scheduled_stop_point_ref&.ref
        end

        def stop_area_id
          return @stop_area_id if defined?(@stop_area_id)

          @stop_area_id = find_stop_area_id
        end

        def find_stop_area_id
          stop_area_code = find_stop_area_code
          unless stop_area_code
            errors.add(:stop_area_code_empty)
            return
          end

          stop_area_id = lookup.stop_areas.find_id(stop_area_code)
          unless stop_area_id
            errors.add(:stop_area_not_found, message_attributes: { code: stop_area_code })
            return
          end

          stop_area_id
        end

        def find_stop_area_code
          raise NotImplementedError
        end

        def flexible?
          raise NotImplementedError
        end
      end

      class PassengerStopAssignmentDecorator < StopAssignmentDecorator
        def find_stop_area_code
          quay_ref&.ref || stop_place_ref&.ref
        end

        def flexible?
          false
        end
      end

      class FlexibleStopAssignmentDecorator < StopAssignmentDecorator
        def find_stop_area_code
          flexible_stop_place_ref&.ref
        end

        def flexible?
          true
        end
      end
    end

    class RoutingConstraintZones < WithResourcePart
      delegate :netex_source, :code_space, :scheduled_stop_points, :line_provider,
               :stop_area_provider, :event_handler, :lookup, to: :import

      def import!
        return unless line_provider

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

        def line_ids
          lookup.lines.find_ids(line_codes)
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

        def valid?
          code_value.present? && line_codes.present? && scheduled_stop_point_ids.present?
        end

        def attributes
          {
            name: name,
            stop_area_ids: stop_area_ids,
            line_ids: line_ids,
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
                resource_attributes: event.resource.tags.transform_keys do |k|
                  case k
                  when :line
                    'line_number'
                  when :column
                    'column_number'
                  else
                    k.to_s
                  end
                end
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
