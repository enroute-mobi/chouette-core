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

  def stop_area_provider
    @stop_area_provider ||= workbench.default_stop_area_provider
  end
  attr_writer :stop_area_provider

	def import_without_status
    import_resources :stop_areas
  end

	def import_stop_areas
		synchronize :stop_area, stop_area_provider
	end

	def netex_source
		@netex_source ||= Netex::Source.read(local_file.path)
	end

	private

	def synchronize(resource_name, target)
    resource = create_resource(resource_name)
    resource.status = "OK"

    event_handler = Chouette::Sync::Event::Handler.new do |event|
      unless event.has_error?
        if event.type.create? || event.type.update?
          resource.inc_rows_count event.count
        end
      else
        resource.status = "ERROR"

        event.errors.each do |attribute, errors|
          errors.each do |error|
            message_attributes = {
              criticity: :error,
              message_key: :invalid_model_attribute,
              message_attributes: {
                attribute_name: attribute,
                attribute_value: error[:value]
              }
            }
            resource.messages.build(message_attributes)
          end
        end
        # TODO Should we saved each time ?
        resource.save!

        self.status = 'failed'
      end
    end
		sync = "Chouette::Sync::#{resource_name.to_s.camelcase}::Netex".constantize.new(
			source: netex_source,
			target: target,
      event_handler: event_handler
		)

		sync.update_or_create

    resource.update_metrics
    resource.save!
	end

	def create_resource(resource_name)
		resources.build(
			name: resource_name,
			resource_type: resource_name.to_s.pluralize,
			reference: resource_name,
		)
	end
end
