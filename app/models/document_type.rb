# frozen_string_literal: true

class DocumentType < ActiveRecord::Base
  belongs_to :workgroup, optional: false

  has_many :documents

  validates :name, presence: true
  validates :short_name, presence: true, uniqueness: { scope: :workgroup_id }, format: { with: /\A[0-9a-zA-Z_]+\Z/ }

  def used?
    documents.exists?
  end
end
