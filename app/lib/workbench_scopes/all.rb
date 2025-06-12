# frozen_string_literal: true

module WorkbenchScopes
  class All
    attr_accessor :workbench

    def initialize(workbench)
      @workbench = workbench
    end

    def lines_scope(initial_scope)
      initial_scope
    end

    def stop_areas_scope(initial_scope)
      initial_scope
    end

    def referentials_scope(initial_scope)
      initial_scope
    end
  end
end
