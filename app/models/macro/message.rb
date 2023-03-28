module Macro
  class Message < ApplicationModel
    self.table_name = "macro_messages"

    extend Enumerize

    def self.policy_class; MacroListRunPolicy end

    belongs_to :source, polymorphic: true, optional: true
    belongs_to :macro_run, class_name: "Macro::Base::Run", optional: false

    enumerize :criticity, in: %w[info warning error], default: 'info', scope: :shallow

    def full_message
      message_attributes.merge!(target_model: source_type.constantize.model_name.human) if source

      I18n.t(
        "#{macro_run.class.name.underscore}.messages.#{message_key || 'default'}",
        message_attributes.symbolize_keys
      )
    end
  end
end
