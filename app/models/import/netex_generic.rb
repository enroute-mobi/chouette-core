class Import::NetexGeneric < Import::Base
	include LocalImportSupport
	include Imports::WithoutReferentialSupport

	delegate :stop_area_referential, :line_referential, to: :workbench

	def self.accepts_file?(file)
		!!Netex::Source.read(file)
  rescue => e
    Chouette::Safe.capture "Error in testing NeTEx file: #{file}", e
    false
  end

	def import_without_status
    import_resources(
			:stop_areas
		)
  end

	def import_stop_areas
		synchronize(:stop_area, stop_area_referential)
	end

	# def import_lines
	# 	synchronize(:line, line_referential)
	# end	

	# def import_companies
	# 	synchronize(:company, line_referential)
	# end

	def netex_source
		@netex_source ||= Netex::Source.read(file.current_path)
	end

	private

	def synchronize(resource_name, target)
		sync = "Chouette::Sync::#{resource_name.to_s.camelcase}::Netex".constantize.new(
			source: netex_source,
			target: target
		)

		sync.update_or_create

		create_resource(sync.counters, resource_name)
		
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

		counters.count(:errors).times do
			resource.messages.build(criticity: :error)
		end

		resource.transaction do
			resource.save!
			resource.update_status_from_messages
		end
	end
end
