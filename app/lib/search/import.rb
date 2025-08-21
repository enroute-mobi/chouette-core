# frozen_string_literal: true

module Search
  class Import < AbstractImport
    attr_accessor :workbench
    attribute :tags

    def query(scope)
      super.tags(tags)
    end

    class Chart < superclass::Chart
      group_by_attribute 'creator', :string
    end
  end
end
