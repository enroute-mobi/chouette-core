# frozen_string_literal: true

module ControlMacro
  module Message
    extend ActiveSupport::Concern

    def full_message
      I18n.t(i18n_key, **i18n_attributes)
    end

    private

    def run
      raise NotImplementedError
    end

    def i18n_key
      raise NotImplementedError
    end

    def i18n_source_attributes
      return {} unless source_type

      source_model_name = source_type.constantize.model_name
      the_human = source_model_name.the_human

      {
        'source|model_name': source_model_name.human,
        'source|the_model_name': the_human,
        'source|The_model_name': the_human.upcase_first,
        'source|of_model_name': source_model_name.of_human,
        'source|to_model_name': source_model_name.to_human
      }
    end

    def i18n_target_attribute
      run.try(:model_attribute)&.human_name
    end

    def i18n_attributes
      message_attributes.symbolize_keys.merge(i18n_source_attributes).tap do |attributes|
        attributes[:target_attribute] = i18n_target_attribute if i18n_target_attribute
      end
    end
  end
end
