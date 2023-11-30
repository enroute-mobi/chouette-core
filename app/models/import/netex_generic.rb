# frozen_string_literal: true

class Import::NetexGeneric < Import::Base
  include LocalImportSupport
  include Imports::WithoutReferentialSupport

  attr_accessor :imported_line_ids

  def self.accepts_file?(file)
    case File.extname(file)
    when '.xml'
      true
    when '.zip'
      Zip::File.open(file) do |zip_file|
        files_count = zip_file.glob('*').size
        zip_file.glob('*.xml').size == files_count
      end
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
        TimeTables
      ].each do |part_class|
        part(part_class, target: referential).import!
      end

      referential.ready!
    rescue StandardError => e
      referential.failed!
      raise e
    end

    update_import_status
  end

  def within_referential(&block)
    referential_builder.create do |referential|
      self.referential = referential
      referential.switch

      block.call referential

      referential.ready!
    end

    return if referential_builder.valid?

    # Create a global error message
    messages.create criticity: :error, message_key: 'referential_creation_overlapping_existing_referential'
    # Save overlapping referentials for user display
    # self.overlapping_referential_ids = referential_builder.overlapping_referential_ids
  end

  def referential_builder
    @referential_builder ||= ReferentialBuilder.new(workbench, name: name, metadata: referential_metadata)
  end

  def referential_metadata
    return unless [imported_line_ids, netex_source.validity_period].all?(&:present?)

    @referential_metadata ||=
      ReferentialMetadata.new line_ids: imported_line_ids, periodes: [netex_source.validity_period]
  end

  # Create a Referential with given name and medata
  class ReferentialBuilder
    def initialize(workbench, name:, metadata:)
      @workbench = workbench
      @name = name
      @metadata = metadata
    end
    attr_reader :workbench, :name, :metadata

    delegate :organisation, to: :workbench

    def create(&block)
      if valid?
        Rails.logger.debug "Create imported Referential: #{referential.inspect}"
        block.call referential
      else
        Rails.logger.debug "Can't created imported Referential: #{referential.inspect}"
      end
    end

    def referential
      @referential ||= workbench.referentials.create(
        name: name,
        organisation: organisation,
        metadatas: [metadata],
        ready: false
      )
    end

    def valid?
      @valid ||= referential.valid?
    end

    def overlapping_referential_ids
      @overlapping_referential_ids ||= referential.overlapped_referential_ids
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

  def part(part_class, target: nil)
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

    part_class.new(self, target: target)
  end

  class Part
    def initialize(import, target: nil)
      @import = import
      @target = target
    end
    attr_reader :import, :target

    # To define callback in import!
    include AroundMethod
    around_method :import!

    extend ActiveModel::Callbacks
    define_model_callbacks :import

    def around_import!(&block)
      run_callbacks :import do
        block.call
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

    delegate :netex_source, :event_handler, :code_space, :disable_missing_resources?, :strict_mode?, to: :import

    def import!
      synchronization.tap do |sync|
        sync.source = netex_source
        sync.event_handler = event_handler
        sync.code_space = code_space
        sync.default_provider = default_provider
        sync.strict_mode = strict_mode?

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

  class RouteJourneyPatterns < WithResourcePart
    delegate :netex_source, :scheduled_stop_points, :line_provider, :event_handler, :referential, to: :import

    def import!
      each_route_with_journey_patterns do |netex_route, netex_journey_patterns|
        decorator = Decorator.new(
          netex_route, netex_journey_patterns,
          scheduled_stop_points: scheduled_stop_points,
          route_points: route_points,
          directions: directions,
          destination_displays: destination_displays,
          line_provider: line_provider
        )

        decorator.errors.each { |error| create_message error } unless decorator.valid?

        save_route decorator.chouette_route
      end

      referential_inserter.flush
    end

    def save_route(route)
      if route.valid?
        referential_inserter.routes << route
        route.stop_points.each do |stop_point|
          stop_point.route_id = route.id
          referential_inserter.stop_points << stop_point
        end

        save_journey_patterns route
      else
        create_message :route_invalid
      end
    end

    def save_journey_patterns(route)
      route.journey_patterns.each do |journey_pattern|
        journey_pattern.route_id = route.id
        if journey_pattern.valid?
          referential_inserter.journey_patterns << journey_pattern
          journey_pattern.journey_pattern_stop_points.each do |journey_pattern_stop_point|
            journey_pattern_stop_point.journey_pattern_id = journey_pattern.id
            journey_pattern_stop_point.stop_point_id = journey_pattern_stop_point.stop_point.id
            referential_inserter.journey_pattern_stop_points << journey_pattern_stop_point
          end
        else
          Rails.logger.debug "Invalid JourneyPattern: #{journey_pattern.errors.inspect}"
          create_message :journey_pattern_invalid
        end
      end
    end

    def prepare_route(chouette_route)
      if chouette_route&.valid?
        referential_inserter.routes << chouette_route
        chouette_route.stop_points.each do |stop_point|
          stop_point.route_id = chouette_route.id
          referential_inserter.stop_points << stop_point
        end
      else
        create_message :route_invalid
      end

      chouette_route
    end

    def prepare_journey_patterns(chouette_route, netex_journey_patterns, route_decorator)
      netex_journey_patterns.each do |netex_journey_pattern|
        chouette_journey_pattern = JourneyPatternDecorator.new(route_decorator,
                                                               netex_journey_pattern).chouette_journey_pattern
        chouette_route.journey_patterns << chouette_journey_pattern
        chouette_journey_pattern.route_id = chouette_route.id
        if chouette_journey_pattern&.valid?
          referential_inserter.journey_patterns << chouette_journey_pattern
          chouette_journey_pattern.journey_patterns_stop_points.each do |journey_pattern_stop_point|
            journey_pattern_stop_point.journey_pattern_id = chouette_journey_pattern.id
            referential_inserter.journey_patterns_stop_points << journey_pattern_stop_point
          end
        else
          create_message :journey_pattern_invalid
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

    def each_route_with_journey_patterns(&block)
      netex_source.routes.each do |route|
        journey_patterns = netex_source.journey_patterns.find_by(route_ref: route.id)
        block.call route, journey_patterns
      end
    end

    def route_points
      @route_points ||= netex_source.route_points
    end

    def directions
      @directions ||= netex_source.directions
    end

    def destination_displays
      @destination_displays ||= netex_source.destination_displays
    end

    class Decorator < SimpleDelegator
      def initialize(route, journey_patterns, scheduled_stop_points: nil, route_points: nil, directions: nil, destination_displays: nil, line_provider: nil)
        super route

        @journey_patterns = journey_patterns
        @scheduled_stop_points = scheduled_stop_points
        @route_points = route_points
        @directions = directions
        @destination_displays = destination_displays
        @line_provider = line_provider
      end
      attr_accessor :journey_patterns, :scheduled_stop_points, :route_points, :directions, :line_provider,
                    :destination_displays

      def chouette_line
        line = line_provider.lines.find_by(registration_number: line_ref&.ref)
        add_error :line_not_found unless line

        line
      end

      def chouette_route
        chouette_line.routes.build(route_attributes).tap do |chouette_route|
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
          name: name,
          wayback: wayback,
          published_name: direction_name,
          stop_points: stop_points
        }
      end

      def wayback
        if Chouette::Route.wayback.values.include?(direction_type)
          direction_type
        else
          add_error :direction_type_not_found
          nil
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

      def route_point_refs
        points_in_sequence
          .sort_by { |point_on_route| point_on_route.order.to_i }
          .map { |point_on_route| point_on_route.route_point_ref&.ref }
      end

      def route_scheduled_point_refs
        route_point_refs.map do |route_point_ref|
          route_point = route_points.find route_point_ref
          if route_point
            route_point.projections.first&.project_to_point_ref&.ref
          else
            add_error :direction_not_found_in_netex_source
          end
        end
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
        end
      end

      def add_error(message_key)
        errors << message_key
      end

      def errors
        @errors ||= []
      end

      def valid?
        errors.empty?
      end
    end

    class JourneyPatternDecorator < SimpleDelegator
      def initialize(route_decorator, journey_pattern)
        super journey_pattern

        @route_decorator = route_decorator
      end
      attr_accessor :route_decorator

      delegate :destination_displays, to: :route_decorator

      def chouette_journey_pattern
        Chouette::JourneyPattern.new journey_pattern_attributes
      end

      def journey_pattern_attributes
        {
          name: name,
          published_name: published_name,
          journey_pattern_stop_points: journey_pattern_stop_points
        }
      end

      def published_name
        destination_display&.front_text
      end

      def destination_display
        destination_displays.find(destination_display_ref&.ref)
      end

      def scheduled_point_ids
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
    delegate :netex_source, to: :import

    def import!
      each_day_type_with_assignements_and_periods do |day_type, day_type_assignments, operating_periods|

        decorator = Decorator.new(day_type, day_type_assignments, operating_periods)
        decorator.errors.each { |error| create_message error } unless decorator.valid?

        time_table = decorator.time_table
        next unless time_table&.valid?

        save(time_table, referential_inserter)
      end

      referential_inserter.flush
    end

    def each_day_type_with_assignements_and_periods(&block)
      netex_source.day_types.each do |day_type|
        day_type_assignments = netex_source.day_type_assignments.find_by(day_type_ref: day_type.id)

        operating_period_ids = day_type_assignments.map { |a| a.operating_period_ref&.ref }
        operating_periods = operating_period_ids.map {|id| netex_source.operating_periods.find id }.reject(&:blank?)

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
    end

    def referential_inserter
      @referential_inserter ||= ReferentialInserter.new(target) do |config|
        config.add IdInserter
        config.add ObjectidInserter
        config.add CopyInserter
      end
    end

    class Decorator < SimpleDelegator
      def initialize(day_type, day_type_assignments, operating_periods)
        super day_type

        @day_type_assignments = day_type_assignments
        @operating_periods = operating_periods
      end
      attr_reader :day_type_assignments, :operating_periods

      def valid?
        errors.empty?
      end

      def errors
        @errors ||= []
      end

      def days_of_week
        Timetable::DaysOfWeek.new.tap do |days_of_week|
          %i[monday tuesday wednesday thursday friday saturday sunday].each do |day|
            days_of_week.enable day if self.send "#{day}?"
          end
        end
      end

      def day_type_assignments_with_date
        @day_type_assignments_with_date ||= day_type_assignments.select { |assigment| assigment.date }
      end

      def included_dates
        day_type_assignments_with_date.select(&:available?).map(&:date)
      end

      def excluded_dates
        day_type_assignments_with_date.reject(&:available?).map(&:date)
      end

      def memory_timetable_periods
        operating_periods.map do |operating_period|
          period = Timetable::Period.from(operating_period.date_range, days_of_week)
        end
      end

      def time_table
        return nil if name.blank?

        @time_table ||= Chouette::TimeTable.new(comment: name).apply(memory_timetable).tap do |time_table|
          now = Time.now
          time_table.created_at = now
          time_table.updated_at = now
        end
      end

      def memory_timetable
        @memory_timetable ||= Timetable.new(
          periods: memory_timetable_periods,
          included_dates: included_dates,
          excluded_dates: excluded_dates
        ).normalize!
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
          line_routing_constraint_zone.errors.each do |attribute, _|
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
          line_referential: line_referential
        }
      end

      delegate :line_referential, to: :line_provider

      def line_routing_constraint_zone
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
    @netex_source ||= Netex::Source.new(include_raw_xml: store_xml?).tap do |source|
      source.transformers << Netex::Transformer::LocationFromCoordinates.new
      source.transformers << Netex::Transformer::Indexer.new(Netex::JourneyPattern, by: :route_ref)
      source.transformers << Netex::Transformer::Indexer.new(Netex::DayTypeAssignment, by: :day_type_ref)

      source.read(local_file.path, type: file_extension)
    end
  end

  def line_ids
    []
  end
end
