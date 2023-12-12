module ImportResourcesSupport
  extend ActiveSupport::Concern

  def main_resource
    @resource ||= parent.resources.find_or_create_by(name: referential_name, resource_type: 'referential', reference: self.name) if parent
  end

  def update_main_resource_status
    main_resource&.update_status_from_importer status
    true
  end

  def create_message args, opts={}
    resource = opts[:resource] || main_resource || self
    message = resource.messages.build args
    return message unless opts[:commit]
    begin
      resource.save!
    rescue
      Rails.logger.error "Invalid resource: #{resource.errors.inspect}"
      Rails.logger.error "Last message: #{resource.messages.last.errors.inspect}"
      raise
    end
    resource.update_status_from_messages
  end

  def create_resource name
    resources.find_or_initialize_by(name: name, resource_type: 'file', reference: name).tap do |r|
      r.import = self
    end
  end
end
