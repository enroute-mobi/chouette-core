class ComplianceControlSetDecorator < Draper::Decorator
  delegate_all

  def action_links
    policy = h.policy(object)
    links = []

    if policy.update?
      links << Link.new(
        content: h.t('compliance_control_sets.actions.edit'),
        href:  h.edit_compliance_control_set_path(object.id)
      )
    end

    if policy.clone?
      links << Link.new(
        content: h.t('actions.clone'),
        href: h.clone_compliance_control_set_path(object.id)
      )
    end

    if policy.destroy?
      links << Link.new(
        content: h.destroy_link_content,
        href: h.compliance_control_set_path(object.id),
        method: :delete,
        data: { confirm: h.t('compliance_control_sets.actions.destroy_confirm') }
      )
    end

    links
  end

end

