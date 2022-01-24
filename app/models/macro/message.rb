module Macro
  class Message < ApplicationModel
    self.table_name = "macro_messages"

    belongs_to :source, polymorphic: true, optional: false
    belongs_to :macro_run, class_name: "Macro::Base::Run", optional: false

    validates_inclusion_of :criticity, in: [ "info", "warning", "error" ]
  end
end