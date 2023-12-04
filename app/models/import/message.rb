class Import::Message < ApplicationModel
  self.table_name = :import_messages

  include IevInterfaces::Message

  belongs_to :import, class_name: 'Import::Base' # TODO: CHOUETTE-3247 optional: true?
  belongs_to :resource, class_name: 'Import::Resource' # TODO: CHOUETTE-3247 optional: true?
  scope :warnings_or_errors, -> { where(criticity: [:warning, :error]) }

  # Use this fix to prevent i18n to use key "import/message"
  def self.custom_i18n_key
    "import_message"
  end

end
