module Macro
  class Base < ApplicationModel
    self.table_name = "macros"

    belongs_to :macro_list, class_name: "Macro::List", optional: false
    acts_as_list scope: :macro_list

    store :options, coder: JSON
  end
end
