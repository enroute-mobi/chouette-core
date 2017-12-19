module StopAreaInOrganisationChecker

  class << self
    def included into
      into.before_action :check_for_stop_area_referential_in_organisation
    end
  end


  private

  def check_for_stop_area_referential_in_organisation
      redirect_to forbidden_path unless 
        StopAreaReferentialMembership
          .where(stop_area_referential_id: stop_area_referential.id, organisation_id: current_organisation.id)
          .exists?
  end

end
