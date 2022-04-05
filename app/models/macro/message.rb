module Macro
  class Message < ApplicationModel
    self.table_name = "macro_messages"

    def self.policy_class; MacroListRunPolicy end

    belongs_to :source, polymorphic: true, optional: false
    belongs_to :macro_run, class_name: "Macro::Base::Run", optional: false

    validates_inclusion_of :criticity, in: [ "info", "warning", "error" ]

    scope :info, -> { where(criticity: :info )  }
    scope :warning, -> { where(criticity: :warning )  }
    scope :error, -> { where(criticity: :error ) }

    def full_message
      I18n.t("macro_messages.#{message_key || 'default'}", message_attributes.symbolize_keys)
    end
  end
end
