class LineReferentialMembership < ApplicationModel
  belongs_to :organisation
  belongs_to :line_referential

  validates :organisation, presence: true, uniqueness: { scope: :line_referential }
end
