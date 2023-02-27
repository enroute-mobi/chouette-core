module Control
  class Message < ApplicationModel
    self.table_name = 'control_messages'

    def self.policy_class
      ControlListRunPolicy
    end

    belongs_to :source, polymorphic: true, optional: false
    belongs_to :control_run, class_name: 'Control::Base::Run', optional: false

    extend Enumerize
    enumerize :criticity, in: %w[warning error]

    scope :warning, -> { where(criticity: :warning) }
    scope :error, -> { where(criticity: :error) }

    def full_message
      I18n.t(
        "control_messages.#{message_key || 'default'}",
        message_attributes.merge(target_model: source_type.constantize.model_name.human).symbolize_keys
      )
    end
  end
end
