class Import::Message < ApplicationModel
  self.table_name = :import_messages

  include IevInterfaces::Message

  belongs_to :import, class_name: 'Import::Base', optional: true # CHOUETTE-3247 failing specs
  belongs_to :resource, class_name: 'Import::Resource', optional: true # CHOUETTE-3247 failing specs
  scope :warnings_or_errors, -> { where(criticity: [:warning, :error]) }

  # Use this fix to prevent i18n to use key "import/message"
  def self.custom_i18n_key
    "import_message"
  end

  def full_message
    return unless i18n_attributes

    I18n.t(i18n_key, **i18n_attributes)
  end

  def i18n_key
    "import_messages.#{message_key || 'default'}"
  end

  def i18n_attributes
    message_attributes&.symbolize_keys
  end

end
