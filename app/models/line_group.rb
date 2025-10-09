# frozen_string_literal: true

class LineGroup < Group
  include LineReferentialSupport
  include NilIfBlank

  has_many :members, class_name: 'LineGroup::Member', foreign_key: :group_id, dependent: :delete_all, inverse_of: :group
  has_many :lines, class_name: 'Chouette::Line', through: :members, inverse_of: :groups

  validates :line_ids, length: { minimum: 1 }

  scope :with_short_name, -> { where.not(short_name: nil) }

  def self.nullable_attributes
    %i[
      short_name
    ]
  end

  class Member < Group::Member
    belongs_to :line, class_name: 'Chouette::Line' # CHOUETTE-3247 code analysis
    validates :line_id, uniqueness: { scope: %i[group_id] }
  end
end
