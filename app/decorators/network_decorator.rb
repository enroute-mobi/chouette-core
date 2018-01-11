class NetworkDecorator < Draper::Decorator
  decorates Chouette::Network

  delegate_all

  # Requires:
  #   context: {
  #     line_referential: ,
  #   }
  def action_links
    links = []

    if h.policy(Chouette::Network).create?
      links << Link.new(
        content: h.t('networks.actions.new'),
        href: h.new_line_referential_network_path(context[:line_referential])
      )
    end

    if h.policy(object).update?
      links << Link.new(
        content: h.t('networks.actions.edit'),
        href: h.edit_line_referential_network_path(
          context[:line_referential],
          object
        )
      )
    end

    if h.policy(object).destroy?
      links << Link.new(
        content: h.destroy_link_content('networks.actions.destroy'),
        href: h.line_referential_network_path(
          context[:line_referential],
          object
        ),
        method: :delete,
        data: { confirm: h.t('networks.actions.destroy_confirm') }
      )
    end

    links
  end
end
