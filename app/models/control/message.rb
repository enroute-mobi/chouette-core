# frozen_string_literal: true

module Control
  class Message < ApplicationModel
    self.table_name = 'control_messages'

    include ControlMacro::Message

    belongs_to :source, polymorphic: true # CHOUETTE-3247 optional: false
    belongs_to :control_run, class_name: 'Control::Base::Run', inverse_of: nil # see comment in CHOUETTE-4628

    extend Enumerize
    enumerize :criticity, in: %w[warning error]

    scope :warning, -> { where(criticity: :warning) }
    scope :error, -> { where(criticity: :error) }

    private

    alias run control_run

    def i18n_key
      "control_messages.#{message_key || 'default'}"
    end
  end
end
