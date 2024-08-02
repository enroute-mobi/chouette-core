# frozen_string_literal: true

module Search
  class Import < AbstractImport
    attr_accessor :workbench

    class Chart < superclass::Chart
      group_by_attribute 'creator', :string
    end
  end
end
