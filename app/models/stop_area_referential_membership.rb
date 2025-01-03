class StopAreaReferentialMembership < ApplicationModel
  belongs_to :organisation # CHOUETTE-3247 validates presence
  belongs_to :stop_area_referential # TODO: CHOUETTE-3247 optional: true?

  validates :organisation, uniqueness: { scope: :stop_area_referential }
end
