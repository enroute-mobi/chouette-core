module Macro
  class List < ApplicationModel
    self.table_name = "macro_lists"

    belongs_to :workbench, optional: false
    validates :name, presence: true

    has_many :macros, -> { order(position: :asc) }, class_name: "Macro::Base", dependent: :delete_all, foreign_key: "macro_list_id", inverse_of: :macro_list

    accepts_nested_attributes_for :macros, allow_destroy: true, reject_if: :all_blank

    def self.policy_class
      MacroListPolicy
    end
  end
end
