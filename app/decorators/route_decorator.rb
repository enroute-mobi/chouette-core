class RouteDecorator < Draper::Decorator
  decorates Chouette::Route

  delegate_all

  # Requires:
  #   context: {
  #     referential: ,
  #     line:
  #   }
  def action_links
    links = []

    if object.stop_points.any?
      links << Link.new(
        content: h.t('journey_patterns.index.title', route: object.name),
        href: [
          context[:referential],
          context[:line],
          object,
          :journey_patterns_collection
        ]
      )
    end

    if object.journey_patterns.present?
      links << Link.new(
        content: h.t('vehicle_journeys.actions.index'),
        href: [
          context[:referential],
          context[:line],
          object,
          :vehicle_journeys
        ]
      )
    end

    links << Link.new(
      content: h.t('vehicle_journey_exports.new.title'),
      href: h.referential_line_route_vehicle_journey_exports_path(
        context[:referential],
        context[:line],
        object,
        format: :zip
      )
    )

    if h.policy(object).duplicate?
      links << Link.new(
        content: h.t('routes.duplicate.title'),
        href: h.duplicate_referential_line_route_path(
          context[:referential],
          context[:line],
          object
        ),
        method: :post
      )
    end

    if h.policy(object).destroy?
      links << Link.new(
        content: h.destroy_link_content,
        href: h.referential_line_route_path(
          context[:referential],
          context[:line],
          object
        ),
        method: :delete,
        data: { confirm: h.t('routes.actions.destroy_confirm') }
      )
    end

    links
  end
end
