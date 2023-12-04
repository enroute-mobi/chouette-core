class LineReferentialMembership < ApplicationModel
  belongs_to :organisation # CHOUETTE-3247 validates presence
  belongs_to :line_referential # TODO: CHOUETTE-3247 optional: true?

  validates :organisation, uniqueness: { scope: :line_referential }
end
