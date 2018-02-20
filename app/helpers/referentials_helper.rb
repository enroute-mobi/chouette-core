module ReferentialsHelper
  # Outputs a green check icon and the text "Oui" or a red exclamation mark
  # icon and the text "Non" based on `status`
  def line_status(status)
    if status
      content_tag(:span, nil, class: 'fa fa-exclamation-circle fa-lg text-danger') +
        t('false')
    else
      content_tag(:span, nil, class: 'fa fa-check-circle fa-lg text-success') +
        t('true')
    end
  end

  def referential_overview referential
    service = ReferentialOverview.new referential, self
    render partial: "referentials/overview", locals: {referential: referential, overview: service}
  end

  def mutual_workbench workbench
    current_user.organisation.workbenches.where(workgroup_id: workbench.workgroup_id).last
  end

  def duplicate_workbench_referential_path referential
    workbench = mutual_workbench referential.workbench
    raise "Missing workbench for referential #{referential.name}" unless workbench.present?
    new_workbench_referential_path(workbench, from: referential.id)
  end
end
