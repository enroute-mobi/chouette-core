# frozen_string_literal: true

class Document < ApplicationModel
  include CodeSupport

  belongs_to :document_type, required: true
  belongs_to :document_provider, required: true

  has_many :codes, as: :resource, dependent: :delete_all
  has_many :memberships, class_name: 'DocumentMembership', dependent: :delete_all
  has_many :lines, through: :memberships, source: :documentable, source_type: 'Chouette::Line'

  mount_uploader :file, DocumentUploader

  attribute :validity_period, Period::Type.new, range: true
  validates :name, :file, :document_type_id, :document_provider_id, presence: true

  validates_associated :codes
  # Can't use it for the moment because it fails with an error
  # "convert endless range to an array error due to Array conversion" in AssociatedValidator
  # validates_associated :validity_period
  validates :validity_period, valid: true

  def validity_period_attributes=(validity_period_attributes)
    period = Period.new(from: validity_period_attributes['from'],
                        to: validity_period_attributes['to'])
    period = nil if period.empty?

    self.validity_period = period
  end

  def self.file_extension_whitelist
    %w[pdf kml jpg jpeg png]
  end
end
