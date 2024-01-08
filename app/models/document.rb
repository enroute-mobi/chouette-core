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

  scope :with_type, ->(document_type) { where(document_type: document_type) }
  scope :valid_on, -> (date) { where('validity_period is null or validity_period @> DATE ?', date) }

  def self.most_updated!
    order(updated_at: :desc).first!
  end

  def validity_period_attributes=(validity_period_attributes)
    period = Period.new(from: validity_period_attributes['from'],
                        to: validity_period_attributes['to'])
    period = nil if period.empty?

    self.validity_period = period
  end

  def self.file_extension_whitelist
    %w[pdf jpg jpeg png]
  end

  # Returns all attributes of the export file from the user point of view
  def user_file
    Chouette::UserFile.new basename: name.parameterize, extension: file_extension, content_type: content_type
  end

  def content_type
    content_type = file&.content_type

    case content_type
    when "application/octet-stream"
      "application/zip"
    else
      content_type
    end
  end

  def file_extension
    File.extname(file.path)[1..-1]
  end

end
