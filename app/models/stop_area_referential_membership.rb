class StopAreaReferentialMembership < ApplicationModel
  belongs_to :organisation
  belongs_to :stop_area_referential

  validates :organisation, presence: true, uniqueness: { scope: :stop_area_referential }
end
