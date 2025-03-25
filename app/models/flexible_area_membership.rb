# frozen_string_literal: true

class FlexibleAreaMembership < ApplicationModel
  belongs_to :flexible_area, class_name: 'Chouette::StopArea', optional: true, inverse_of: :flexible_area_memberships
  belongs_to :member, class_name: 'Chouette::StopArea', inverse_of: :flexible_area_memberships_as_member

  validates :member_id, uniqueness: { scope: :flexible_area_id }
  validate :flexible_area_must_be_flexible_stop_place
  validate :member_cannot_be_flexible_stop_place

  private

  def flexible_area_must_be_flexible_stop_place
    return if flexible_area&.flexible_stop_place?

    errors.add(:flexible_area_id, :must_be_flexible_stop_place)
  end

  def member_cannot_be_flexible_stop_place
    return unless member&.flexible_stop_place?

    errors.add(:member_id, :cannot_be_flexible_stop_place)
  end
end
