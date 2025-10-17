# frozen_string_literal: true

module Macro
  class Message < ApplicationModel
    self.table_name = 'macro_messages'

    include ControlMacro::Message

    extend Enumerize

    belongs_to :source, polymorphic: true, optional: true # CHOUETTE-3247
    belongs_to :macro_run, class_name: 'Macro::Base::Run', inverse_of: nil # see comment in CHOUETTE-4628

    enumerize :criticity, in: %w[info warning error], default: 'info', scope: :shallow

    private

    alias run macro_run

    def i18n_key
      "#{macro_run.class.name.underscore}.messages.#{message_key || 'default'}"
    end
  end
end
