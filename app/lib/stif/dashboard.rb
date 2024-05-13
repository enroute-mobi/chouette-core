module Stif
  class Dashboard < ::Dashboard
    def workbench
      if current_user.workbenches.length > 1
        Rails.logger.error("Organisation #{current_organisation.name} should have only one workbench")
      end
      @workbench ||= current_user.workbenches.first
    end

    def workgroup
      workbench.workgroup
    end

    def referentials
      @referentials ||= self.workbench.all_referentials
    end

    def calendars
      workbench.calendars_with_shared
    end
  end
end
