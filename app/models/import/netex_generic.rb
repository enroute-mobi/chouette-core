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

  # shapes
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

    within_referential

    update_import_status
  end

  def within_referential(&block)
    referential_builder.create do |referential|
      referential.switch

      yield referential
    end

    unless referential_builder.valid?
      # Create a global error message
      messages.create criticity: :error, message_key: 'referential_creation_overlapping_existing_referential'
      # Save overlapping referentials for user display
      #self.overlapping_referential_ids = referential_builder.overlapping_referential_ids
    end
  end

  def referential_builder
    ReferentialBuilder.new(workbench, name: name, metadata: referential_metadata)
  end

  def referential_metadata
    @referential_metadata ||=
      ReferentialMetadata.new line_ids: imported_line_ids, periodes: [netex_source.validity_period]
  end

  class ReferentialBuilder
    def initialize(workbench, name:, metadata:)
      @workbench = workbench
      @name = name
      @metadata = metadata
    end
    attr_reader :workbench, :name, :metadata

    delegate :organisation, to: :workbench

    def create(&block)
      yield referential if valid?
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
      @overlapping_referentials ||= referential.overlapped_referential_ids
    end
  end

  # TODO: why the resource statuses are not checked automaticaly ??
  # See CHOUETTE-2747
  def update_import_status
    resource_status = resources.map(&:status).uniq.map(&:to_s)
    Rails.logger.debug "resource_status: #{resource_status.inspect}"

    if resource_status.include?('ERROR')
      self.status = 'failed'
    elsif resource_status.include?('WARNING')
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

    part_class.new(self)
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

      def line_referential
        line_provider.line_referential
      end

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
      source.read(local_file.path, type: file_extension)
    end
  end

  def line_ids
    []
  end
end
