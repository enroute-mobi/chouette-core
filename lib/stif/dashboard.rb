module Stif
  class Dashboard < ::Dashboard
    def workbench
      @workbench ||= current_organisation.workbenches.default
    end

    def workgroup
      workbench.workgroup
    end

    def referentials
      @referentials ||= self.workbench.all_referentials
    end

    def calendars
      workbench.calendars
    end
  end
end
