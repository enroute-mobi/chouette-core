module Control
  class Message < ApplicationModel
    self.table_name = 'control_messages'

    belongs_to :source, polymorphic: true, optional: false
    belongs_to :control_run, class_name: 'Control::Base::Run', optional: false

    extend Enumerize
    enumerize :criticity, in: %w[warning error]

    scope :warning, -> { where(criticity: :warning) }
    scope :error, -> { where(criticity: :error) }

    def full_message
      I18n.t("control_messages.#{message_key || 'default'}", human_message_attributes)
    end

    def human_message_attributes
      message_attributes.merge(
        target_model: source_type.constantize.model_name.human
      ).tap do |human_message_attributes|
        if model_attribute = control_run.try(:model_attribute)
          human_message_attributes[:target_attribute] = model_attribute.human_name
        end
      end.symbolize_keys
    end
  end
end
