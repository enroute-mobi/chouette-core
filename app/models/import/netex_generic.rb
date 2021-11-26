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
    workbench.default_stop_area_provider
  end

	def import_without_status
    import_resources(
			:stop_areas
		)
  end

	def import_stop_areas
		synchronize(:stop_area, stop_area_provider) do |updater, model, resource|
			resource.codes.each do |key_value|
				CodeSpace.find_by_short_name!(key_value.key)
			rescue ActiveRecord::RecordNotFound
				updater.report_invalid_model(
					model: model,
					resource: resource,
					import_message: {
						criticity: :error,
						message_key: :code_space_error,
						message_attributes: {
							short_name: key_value.value
						}
					}
				)
			end
		end
	end

	def netex_source
		@netex_source ||= Netex::Source.read(local_file.path)
	end

	private

	def synchronize(resource_name, target, &block)
		sync = "Chouette::Sync::#{resource_name.to_s.camelcase}::Netex".constantize.new(
			source: netex_source,
			target: target
		)

		sync.update_or_create(&block)

		resource = create_resource(sync.counters, resource_name)
		
		if sync.counters.count(:errors) > 0
			@status = 'failed'
		end
	
		sync
	end

	def create_resource(counters, resource_name)
		return if counters.total == 0

		resource = resources.find_or_initialize_by(
			name: resource_name,
			resource_type: resource_name.to_s.pluralize,
			reference: resource_name,
		).tap do |r|
			r.rows_count = counters.total
      r.import = self
    end

		counters.get(:errors).each do |error|
			message_attributes = (error[:import_message] || {}).reverse_merge(criticity: :error)
			resource.messages.build(message_attributes)
		end

		resource.transaction do
			resource.save!
			resource.update_status_from_messages
		end

		resource
	end
end
