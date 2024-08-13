# frozen_string_literal: true

module Macro
  class Message < ApplicationModel
    self.table_name = 'macro_messages'

    extend Enumerize

    belongs_to :source, polymorphic: true, optional: true
    belongs_to :macro_run, class_name: 'Macro::Base::Run', optional: false

    enumerize :criticity, in: %w[info warning error], default: 'info', scope: :shallow

    def full_message
      I18n.t i18n_key, i18n_attributes
    end

    def i18n_key
      "#{macro_run.class.name.underscore}.messages.#{message_key || 'default'}"
    end

    def model_class
      @model_class ||= source_type&.constantize
    end

    def i18n_target_model
      model_class.model_name.human if model_class
    end

    def i18n_target_attribute
      if model_class && macro_run.try(:target_attribute)
        model_class.human_attribute_name(macro_run.target_attribute, locale: I18n.locale)
      end
    end

    def i18n_attributes
      message_attributes.dup.tap do |attributes|
        attributes[:target_model] = i18n_target_model
        attributes[:target_attribute] = i18n_target_attribute
      end.compact.symbolize_keys
    end
  end
end
