class LineDecorator < Draper::Decorator
  decorates Chouette::Line

  delegate_all

  # Requires:
  #   context: {
  #     line_referential: ,
  #     current_organisation:
  #   }
  def action_links
    links = []

    links << Link.new(
      content: h.t('lines.actions.show_network'),
      href: [context[:line_referential], object.network]
    )

    links << Link.new(
      content: h.t('lines.actions.show_company'),
      href: [context[:line_referential], object.company]
    )

    if h.policy(object).destroy?
      links << Link.new(
        content: h.destroy_link_content('lines.actions.destroy'),
        href: h.line_referential_line_path(context[:line_referential], object),
        method: :delete,
        data: {confirm: h.t('lines.actions.destroy_confirm')}
      )
    end

    links
  end
end
