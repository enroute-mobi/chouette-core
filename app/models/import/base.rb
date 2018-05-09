class Import::Base < ApplicationModel
  self.table_name = "imports"
  validates :file, presence: true

  def self.messages_class_name
    "Import::Message"
  end

  def self.resources_class_name
    "Import::Resource"
  end

  def self.file_extension_whitelist
    %w(zip)
  end

  include IevInterfaces::Task

  def self.model_name
    ActiveModel::Name.new Import::Base, Import::Base, "Import"
  end

  def child_change
    Rails.logger.info "child_change for #{inspect}"
    return if self.class.finished_statuses.include?(status)

    super
    update_referentials
  end

  def update_referentials
    Rails.logger.info "update_referentials for #{inspect}"
    return unless self.class.finished_statuses.include?(status)

    # We treat all created referentials in a batch
    # If a single fails, we consider they all failed
    # Ohana means family !
    if self.successful?
      children.map(&:referential).compact.each &:active!
    else
      children.map(&:referential).compact.each &:failed!
    end
  end

  private

  def failed!
    update status: :failed
  end

  def aborted!
    Rails.logger.info "=== aborted ==="
    update status: :aborted
  end

  def initialize_fields
    super
    self.token_download ||= SecureRandom.urlsafe_base64
  end

end
