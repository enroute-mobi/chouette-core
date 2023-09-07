module MetadataControllerSupport
  extend ActiveSupport::Concern

  included do
    after_action :set_creator_metadata, only: :create
    after_action :set_modifier_metadata, only: :update
  end

  def user_for_metadata
    current_user ? (current_user.username.presence || current_user.name) : ''
  end

  def set_creator_metadata
    return unless metadata_resource&.valid?

    metadata_resource.try(:set_metadata!, :creator_username, user_for_metadata)
    metadata_resource.try(:set_metadata!, :modifier_username, user_for_metadata)
  end

  def set_modifier_metadata
    metadata_resources.each do |r|
      r.try(:set_metadata!, :modifier_username, user_for_metadata) if r.persisted? && r.valid?
    end
  end

  def metadata_resource
    @metadata_resource ||= resource if respond_to?(:resource, true)
  end

  def metadata_resources
    @metadata_resources ||= [@resources, [metadata_resource]].to_a.flatten.compact
  end
end
