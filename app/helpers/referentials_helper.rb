module ReferentialsHelper
  # Outputs a green check icon and the text "Oui" or a red exclamation mark
  # icon and the text "Non" based on `status`
  def line_status(status)
    case status
    when :deactivated
      content_tag(:span, nil, class: 'fa fa-exclamation-circle fa-lg text-danger') +
      Chouette::Line.tmf('deactivated')
    else
      content_tag(:span, nil, class: 'fa fa-check-circle fa-lg text-success') +
      Chouette::Line.tmf('activated')
    end
  end

  def icon_for_referential_state state
    case state.to_s
    when "pending"
      "<span class='fa fa-clock-o'></span>"
    when "failed"
      "<span class='fa fa-times'></span>"
    when "archived"
      "<span class='fa fa-archive'></span>"
    else
      "<span class='sb sb-lg sb-preparing'></span>"
    end.html_safe
  end

  def referential_state referential, icon: true
    state_icon = icon && icon_for_referential_state(@referential.state)
    "<div class='td-block'>#{state_icon}<span>#{"referentials.states.#{referential.state}".t}</span></div>".html_safe
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
