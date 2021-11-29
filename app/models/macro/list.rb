module Macro
  class List < ApplicationModel
    self.table_name = "macro_lists"

    belongs_to :workgroup, optional: false
    validates :name, presence: true

    has_many :macros, -> { order(position: :asc) }, class_name: "Macro::Base", dependent: :delete_all, foreign_key: "macro_list_id"
  end
end
