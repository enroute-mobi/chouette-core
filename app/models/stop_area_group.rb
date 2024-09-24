class StopAreaGroup < Group
  include StopAreaReferentialSupport

  has_many :members, class_name: "StopAreaGroup::Member", foreign_key: :group_id, dependent: :destroy, inverse_of: :group
  has_many :stop_areas, class_name: "Chouette::StopArea", through: :members, inverse_of: :groups

  validates :stop_area_ids, length: { minimum: 1 }

  class Member < Group::Member
    belongs_to :stop_area, class_name: "Chouette::StopArea"
    validates :stop_area_id, uniqueness: { scope: %i[group_id] }
  end
end
