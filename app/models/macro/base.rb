module Macro
  class Base < ApplicationModel
    include OptionsSupport # Check which methods are/should be deprecated

    self.table_name = "macros"

    belongs_to :macro_list, class_name: "Macro::List", optional: false, inverse_of: :macros
    acts_as_list scope: :macro_list

    store :options, coder: JSON
  end
end
