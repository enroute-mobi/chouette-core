module ComplianceCheckSetsHelper
  def compliance_check_set_path(compliance_check_set)
    if @parent.is_a?( Workbench )
      workbench_compliance_check_set_path(compliance_check_set.workbench, compliance_check_set)
    else
      workgroup_compliance_check_set_path(compliance_check_set.workgroup, compliance_check_set)
    end
  end

  def executed_compliance_check_set_path(compliance_check_set)
    executed_workbench_compliance_check_set_path(compliance_check_set.workbench, compliance_check_set)
  end

  def compliance_check_path(compliance_check)
    workbench_compliance_check_set_compliance_check_path(
      compliance_check.compliance_check_set.workbench,
      compliance_check.compliance_check_set,
      compliance_check)
  end

    # Import statuses helper
  def compliance_check_set_status(status)
    if %w[new running pending].include? status
      content_tag :span, '', class: "fa fa-clock-o"
    else
      cls =''
      cls = 'success' if status == 'successful'
      cls = 'warning' if status == 'warning'
      cls = 'danger' if %w[failed aborted canceled].include? status

      content_tag :span, '', class: "fa fa-circle text-#{cls}"
    end
  end

  def compliance_check_set_metadatas(check_set)
    metadata = {}
    if @compliance_check_set.referential.nil?
      metadata = metadata.update({ I18n.t("compliance_check_sets.show.metadatas.referential") => '' })
    else
      metadata = metadata.update({ I18n.t("compliance_check_sets.show.metadatas.referential") => link_to_if_i_can(@compliance_check_set.referential.name, @compliance_check_set.referential) })
    end

    metadata = metadata.update({ I18n.t("compliance_check_sets.show.metadatas.referential_type") => 'Jeu de données' })
    metadata = metadata.update({ I18n.t("compliance_check_sets.show.metadatas.status") => operation_status(@compliance_check_set.status, verbose: true) })
    metadata = metadata.update({ I18n.t("compliance_check_sets.show.metadatas.compliance_check_set_executed") => link_to_if_i_can(@compliance_check_set.name, [:executed, @parent, @compliance_check_set]) })
    metadata = metadata.update({ (@parent.is_a?( Workbench ) ? Workbench : Workgroup ).ts.capitalize => link_to_if_i_can(@parent.name, @parent) })

    metadata = metadata.update({  I18n.t("compliance_check_sets.show.metadatas.compliance_control_owner") => @compliance_check_set.organisation.name,
                                  I18n.t("compliance_check_sets.show.metadatas.import") => '',
                                  ComplianceCheckSet.tmf(:context) => @compliance_check_set.context_i18n })
    metadata
  end
end
