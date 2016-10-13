class LineReferential < ActiveRecord::Base
  has_many :line_referential_memberships
  has_many :organisations, through: :line_referential_memberships

  has_many :lines, class_name: 'Chouette::Line'
  has_many :group_of_lines, class_name: 'Chouette::GroupOfLine'
  has_many :companies, class_name: 'Chouette::Company'
  has_many :networks, class_name: 'Chouette::Network'

  has_many :line_referential_syncs, -> { order created_at: :desc}

  def add_member(organisation, options = {})
    attributes = options.merge organisation: organisation
    line_referential_memberships.build attributes
  end

  validates :name, presence: true
  validates :sync_interval, presence: true
  # need to define precise validation rules
  validates_inclusion_of :sync_interval, :in => 1..30

  def operating_lines
    lines.where(deactivated: false)
  end

  def last_sync
    line_referential_syncs.last
  end
end
