class Destination < ApplicationModel
  include OptionsSupport
  include RemoteFilesHandler

  belongs_to :publication_setup, inverse_of: :destinations
  has_many :reports, class_name: 'DestinationReport', dependent: :destroy
  belongs_to :publication_api, class_name: '::PublicationApi'

  validates :name, :type, presence: true

  mount_uploader :secret_file, SecretFileUploader
  validates :secret_file, presence: true, if: :secret_file_required?
  validate :api_is_not_already_used

  @secret_file_required = false

  class << self
    def secret_file_required?
      !!@secret_file_required
    end

    def enabled?(destination_type)
      Rails.application.config.additional_destinations.try :include?, destination_type
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
    rescue => e
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
    self.ts
  end

  def local_secret_file
    return unless self[:secret_file].present?

    local_temp_file secret_file
  end

  private

  def api_is_not_already_used
    return unless publication_api.present?

    scope = publication_api.publication_setups.where(export_type: publication_setup.export_type)
    scope = scope.where('publication_setups.id != ?', publication_setup.id) if publication_setup.persisted?

    if publication_setup.export_type == "Export::Netex"
      scope = scope.where("export_options->export_type = ?", publication_setup.export_options["export_type"])
    end
    return if scope.empty?

    errors.add(:publication_api_id, I18n.t('destinations.errors.publication_api.already_used'))
  end
end

require_dependency './destination/dummy' if ::Destination.enabled?("dummy")
require_dependency './destination/google_cloud_storage' if ::Destination.enabled?("google_cloud_storage")
require_dependency './destination/sftp' if ::Destination.enabled?("sftp")
require_dependency './destination/publication_api'
