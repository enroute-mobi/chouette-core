class StopAreaDecorator < Draper::Decorator
  decorates Chouette::StopArea

  delegate_all

  def action_links(stop_area = nil)
    links = []
    stop_area ||= object

    if h.policy(Chouette::StopArea).create?
      links << Link.new(
        content: h.t('stop_areas.actions.new'),
        href: h.new_stop_area_referential_stop_area_path(
          stop_area.stop_area_referential
        )
      )
    end

    if h.policy(stop_area).update?
      links << Link.new(
        content: h.t('stop_areas.actions.edit'),
        href: h.edit_stop_area_referential_stop_area_path(
          stop_area.stop_area_referential,
          stop_area
        )
      )
    end

    if h.policy(stop_area).destroy?
      links << Link.new(
        content: h.destroy_link_content('stop_areas.actions.destroy'),
        href: h.stop_area_referential_stop_area_path(
          stop_area.stop_area_referential,
          stop_area
        ),
        method: :delete,
        data: { confirm: t('stop_areas.actions.destroy_confirm') }
      )
    end

    links
  end
end
