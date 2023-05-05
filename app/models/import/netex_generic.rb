class Import::NetexGeneric < Import::Base
  include LocalImportSupport
  include Imports::WithoutReferentialSupport

  def self.accepts_file?(file)
    case File.extname(file)
    when ".xml"
      true
    when ".zip"
      Zip::File.open(file) do |zip_file|
        files_count = zip_file.glob('*').size
        zip_file.glob('*.xml').size == files_count
      end
    else
      false
    end
  rescue => e
    Chouette::Safe.capture "Error in testing NeTEx (Generic) file: #{file}", e
    false
  end

  def file_extension_whitelist
    %w(zip xml)
  end

  # stop_areas
  def stop_area_provider
    @stop_area_provider ||= workbench.default_stop_area_provider
  end
  attr_writer :stop_area_provider

  def stop_area_referential
    @stop_area_referential ||= workbench.stop_area_referential
  end
  attr_writer :stop_area_referential

  # lines
  def line_provider
    @line_provider ||= workbench.default_line_provider
  end
  attr_writer :line_provider

  def line_referential
    @line_referential ||= workbench.line_referential
  end
  attr_writer :line_referential

  # shapes
  def shape_provider
    @shape_provider ||= workbench.default_shape_provider
  end
  attr_writer :shape_provider

  def import_without_status
    [
      StopAreaReferential,
      LineReferential,
      ShapeReferential,
    ].each do |part_class|
      part(part_class).import!
    end
  end

  def part(part_class)
    # For test, accept a symbol/name in argument
    # For example: part(:line_referential).import!
    unless part_class.is_a?(Class)
      part_class = self.class.const_get(part_class.to_s.classify)
    end

    part_class.new(self)
  end

  class Part
    def initialize(import)
      @import = import
    end
    attr_reader :import
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

      import.resources.each do |resource|
        resource.update_metrics
        resource.save
      end
    ensure
      import.save
    end

    measure :import!, as: ->(part) { part.class.name.demodulize }
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
      Chouette::Sync::Referential.new(target).tap do |sync|
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

        if processor.has_error?
          import.status = 'failed'
        end
      end
    end

    # Create a Import::Resource
    def resource(netex_resource_class)
      # StopPlace, Quay, ...
      human_netex_resource_name = netex_resource_class.name.demodulize.pluralize

      import.resources.find_or_initialize_by(resource_type: human_netex_resource_name) do |resource|
        resource.name = human_netex_resource_name
        resource.status = "OK"
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
        unless event.has_error?
          if event.type.create? || event.type.update?
            process_create_or_update
          end
        else
          process_error
        end

        # TODO As ugly as necessary
        # Need to save resource because it's used in resource method
        resource.save
      end

      def process_create_or_update
        resource.inc_rows_count event.count
      end

      def process_error
        self.has_error = true
        resource.status = "ERROR"
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
      source.read(local_file.path, type: file_extension)
    end
  end

  def line_ids
    []
  end
end
