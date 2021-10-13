class ComplianceChecksController < ChouetteController
  include PolicyChecker
  defaults resource_class: ComplianceCheck
  
  def parent
    @parent ||= if params[:workgroup_id]
      current_organisation.workgroups.find params[:workgroup_id]
    else
      current_organisation.workbenches.find params[:workbench_id]
    end
  end

  def end_of_association_chain
    @compliance_check_set = parent.compliance_check_sets.find(params[:compliance_check_set_id])
    @compliance_check_set.compliance_checks
  end
end
