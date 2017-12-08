class CompanyDecorator < Draper::Decorator
  decorates Chouette::Company

  delegate_all

  def self.collection_decorator_class
    PaginatingDecorator
  end

  def linecount
    object.lines.count
  end

  # Requires:
  #   context: {
  #     referential:
  #   }
  def action_links
    links = []

    if h.policy(Chouette::Company).create?
      links << Link.new(
        content: h.t('companies.actions.new'),
        href: h.new_line_referential_company_path(context[:referential])
      )
    end

    if h.policy(object).update?
      links << Link.new(
        content: h.t('companies.actions.edit'),
        href: h.edit_line_referential_company_path(
          context[:referential],
          object
        )
      )
    end

    if h.policy(object).destroy?
      links << Link.new(
        content: h.t('companies.actions.destroy'),
        href: h.line_referential_company_path(
          context[:referential],
          object
        ),
        method: :delete,
        data: { confirm: h.t('companies.actions.destroy_confirm') }
      )
    end

    links
  end
end
