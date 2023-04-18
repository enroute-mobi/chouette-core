# frozen_string_literal: true

module Macro
  class Message < ApplicationModel
    self.table_name = 'macro_messages'

    extend Enumerize

    def self.policy_class
      MacroListRunPolicy
    end

    belongs_to :source, polymorphic: true, optional: true
    belongs_to :macro_run, class_name: 'Macro::Base::Run', optional: false

    enumerize :criticity, in: %w[info warning error], default: 'info', scope: :shallow

    def full_message
      I18n.t i18n_key, i18n_attributes
    end

    def i18n_key
      "#{macro_run.class.name.underscore}.messages.#{message_key || 'default'}"
    end

    def i18n_target_model
      source_type.constantize.model_name.human if source_type
    end

    def i18n_attributes
      message_attributes.dup.tap do |attributes|
        attributes[:target_model] = i18n_target_model
      end.compact.symbolize_keys
    end
  end
end
