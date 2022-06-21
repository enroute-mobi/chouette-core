class DocumentType < ActiveRecord::Base

  belongs_to :workgroup, optional: false

  has_many :documents

  validates :name, presence: true
  validates :short_name, presence: true, uniqueness: { scope: :workgroup }, format: { with: %r{\A[0-9a-zA-Z_]+\Z} }

end
