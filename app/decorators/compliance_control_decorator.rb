class ComplianceControlDecorator < Draper::Decorator
  delegate_all

  def action_links
    policy = h.policy(object)
    links = []

    links << Link.new(
      content: h.t('compliance_control_sets.actions.show'),
      href:  h.compliance_control_set_compliance_control_path(object.compliance_control_set.id, object.id)
    )

    if policy.update?
      links << Link.new(
        content: h.t('compliance_controls.actions.edit'),
        href:  h.edit_compliance_control_set_compliance_control_path(object.compliance_control_set.id, object.id)
      )
    end

    if policy.destroy?
      links << Link.new(
        content: h.destroy_link_content,
        href: h.compliance_control_set_compliance_control_path(object.compliance_control_set.id, object.id),
        method: :delete,
        data: { confirm: h.t('compliance_controls.actions.destroy_confirm') }
      )
    end
    links
  end
end
