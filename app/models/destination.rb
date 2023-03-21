class Destination < ApplicationModel
  include OptionsSupport

  belongs_to :publication_setup, inverse_of: :destinations
  has_many :reports, class_name: 'DestinationReport', dependent: :destroy
  belongs_to :publication_api, class_name: '::PublicationApi'

  validates :name, :type, presence: true

  mount_uploader :secret_file, SecretFileUploader
  validates :secret_file, presence: true, if: :secret_file_required?

  @secret_file_required = false

  class << self
    def secret_file_required?
      !!@secret_file_required
    end
  end

  def secret_file_required?
    self.class.secret_file_required?
  end

  def transmit(publication)
    report = reports.find_or_create_by(publication_id: publication.id)
    report.start!
    begin
      do_transmit publication, report
      report.success! unless report.failed?
    rescue StandardError => e
      Chouette::Safe.capture "Destination ##{id} transmission failed for Publication #{publication.id}", e
      report.failed! message: e.message, backtrace: e.backtrace
    end
  end

  def do_transmit(publication, report)
    raise NotImplementedError
  end

  def human_type
    self.class.human_type
  end

  def self.human_type
    ts
  end
end

require_dependency './destination/dummy'
require_dependency './destination/google_cloud_storage'
require_dependency './destination/sftp'
require_dependency './destination/mail'
require_dependency './destination/publication_api'
require_dependency './destination/ara'
