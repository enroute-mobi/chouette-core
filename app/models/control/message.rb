module Control
  class Message < ApplicationModel
    self.table_name = "control_messages"

    belongs_to :source, polymorphic: true, optional: false
    belongs_to :control_run, class_name: "Control::Base::Run", optional: false

    extend Enumerize
    enumerize :criticity, in: %w(warning error)
  end
end
