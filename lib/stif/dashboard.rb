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
      @calendars ||= Calendar.where('(organisation_id = ? OR shared = ?) AND workgroup_id = ?', current_organisation.id, true, workgroup.id)
    end
  end
end
