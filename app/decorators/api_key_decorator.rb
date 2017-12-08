class ApiKeyDecorator < Draper::Decorator
  decorates Api::V1::ApiKey
  delegate_all


  def action_links
    links = []

    links << Link.new(
      content: h.t('api_keys.actions.show'),
      href: h.organisation_api_key_path(object),
    )
    if h.policy(object).update?
      links << Link.new(
        content: h.t('api_keys.actions.edit'),
        href: h.edit_organisation_api_key_path(object),
      )
    end

    if h.policy(object).destroy?
      links << Link.new(
        content: h.destroy_link_content,
        href: h.organisation_api_key_path(object),
        method: :delete,
        data: { confirm: h.t('api_keys.actions.destroy_confirm') }
      )
    end

    links
  end
end
