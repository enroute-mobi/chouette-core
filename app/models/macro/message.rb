module Macro
  class Message < ApplicationModel
    self.table_name = "macro_messages"

    belongs_to :source, polymorphic: true, optional: true

    validates_inclusion_of :criticity, in: [ "info", "warning", "error" ]
  end
end