class LineGroup < Group
  include LineReferentialSupport

  has_many :members, class_name: "LineGroup::Member", foreign_key: :group_id, dependent: :destroy, inverse_of: :group
  has_many :lines, class_name: "Chouette::Line", through: :members, inverse_of: :groups

  validates :line_ids, length: { minimum: 1 }

  class Member < Group::Member
    belongs_to :line, class_name: "Chouette::Line"
    validates :line_id, uniqueness: { scope: %i[group_id] }
  end
end
