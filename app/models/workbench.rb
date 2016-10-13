class Workbench < ActiveRecord::Base
  belongs_to :organisation

  validates :name, presence: true
  validates :organisation, presence: true

  has_many :referentials

end
