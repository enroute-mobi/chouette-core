class DocumentProvider < ActiveRecord::Base
  belongs_to :workbench, required: true

  has_many :documents

  validates :name, presence: true
  validates :short_name, presence: true, uniqueness: { scope: :workbench }, format: { with: /\A[0-9a-zA-Z_]+\Z/ }
end
