class DocumentProvider < ActiveRecord::Base
  belongs_to :workbench # CHOUETTE-3247 required: true

  has_many :documents, dependent: :destroy

  validates :name, presence: true
  validates :short_name, presence: true, uniqueness: { scope: :workbench }, format: { with: /\A[0-9a-zA-Z_]+\Z/ }

  def used?
    documents.exists?
  end
end
