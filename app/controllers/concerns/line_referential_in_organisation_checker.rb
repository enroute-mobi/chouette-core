module LineReferentialInOrganisationChecker

  class << self
    def included into
      into.before_action :check_for_line_referential_in_organisation
    end
  end


  private

  def check_for_line_referential_in_organisation
    redirect_to forbidden_path unless
      LineReferentialMembership
        .where(line_referential_id: line_referential.id, organisation_id: current_organisation.id)
        .exists?
  end
  
end
