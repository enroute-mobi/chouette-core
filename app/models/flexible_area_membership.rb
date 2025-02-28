class FlexibleAreaMembership < ApplicationModel
  belongs_to :flexible_area, class_name: 'Chouette::StopArea', optional: true
  belongs_to :member, class_name: 'Chouette::StopArea'

  # validates :flexible_area_id, uniqueness: { scope: :member_id }
  # validate :flexible_area_must_be_flexible_stop_place
  validate :member_cannot_be_flexible_stop_place

  private

  def flexible_area_must_be_flexible_stop_place
    unless flexible_area&.flexible_stop_place?
      errors.add(:flexible_area, :must_be_flexible_stop_place)
    end
  end

  def member_cannot_be_flexible_stop_place
    if member&.flexible_stop_place?
      errors.add(:member, :cannot_be_flexible_stop_place)
    end
  end
end