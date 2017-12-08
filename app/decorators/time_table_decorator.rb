class TimeTableDecorator < Draper::Decorator
  decorates Chouette::TimeTable

  delegate_all

  # Requires:
  #   context: {
  #     referential: ,
  #   }
  def action_links
    links = []

    if h.policy(object).actualize? && object.calendar
        links << Link.new(
          content: h.t('actions.actualize'),
          href: h.actualize_referential_time_table_path(
            context[:referential],
            object
          ),
          method: :post
        )
      end

    if h.policy(object).update?
      links << Link.new(
        content: h.t('actions.combine'),
        href: h.new_referential_time_table_time_table_combination_path(
          context[:referential],
          object
        )
      )
    end

    if h.policy(object).duplicate?
      links << Link.new(
        content: h.t('actions.duplicate'),
        href: h.duplicate_referential_time_table_path(
          context[:referential],
          object
        )
      )
    end

    if h.policy(object).destroy?
      links << Link.new(
        content: h.destroy_link_content,
        href: h.referential_time_table_path(context[:referential], object),
        method: :delete,
        data: { confirm: h.t('time_tables.actions.destroy_confirm') }
      )
    end

    links
  end
end
