class Import::Base < ApplicationModel
  self.table_name = "imports"
  include OptionsSupport

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
  # we skip validation once the import has been persisted,
  # in order to allow Sidekiq workers (which don't have acces to the file) to
  # save the import
  validates_presence_of :file, unless: Proc.new {|import| import.persisted? || import.errors[:file].present? }

  def self.model_name
    ActiveModel::Name.new Import::Base, Import::Base, "Import"
  end

  def child_change
    Rails.logger.info "child_change for #{inspect}"
    if self.class.finished_statuses.include?(status)
      done! if self.compliance_check_sets.all? &:successful?
    else
      super
    end

  end

  private

  def initialize_fields
    super
    self.token_download ||= SecureRandom.urlsafe_base64
  end

end
