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
    return unless try(:resource)

    if resource.valid?
      resource.try(:set_metadata!, :creator_username, user_for_metadata)
      resource.try(:set_metadata!, :modifier_username, user_for_metadata)
    end
  end

  def set_modifier_metadata
    _resources = @resources || [try(:resource)]
    _resources = _resources.to_a.flatten.compact

    return if _resources.blank?

    _resources.each do |r|
      r.try(:set_metadata!, :modifier_username, user_for_metadata) if r.persisted? && r.valid?
    end
  end
end
