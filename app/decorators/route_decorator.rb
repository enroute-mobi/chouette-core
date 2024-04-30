class RouteDecorator < AF83::Decorator
  decorates Chouette::Route

  set_scope { [context[:workbench], context[:referential], context[:line]] }

  with_instance_decorator do |instance_decorator|
    instance_decorator.show_action_link

    instance_decorator.edit_action_link

    instance_decorator.action_link(
      if: ->() { object.stop_points.any? },
      secondary: :show
    ) do |l|
      l.content t('journey_patterns.actions.index')
      l.href do
        [
          context[:workbench],
          context[:referential],
          context[:line],
          object,
          :journey_patterns
        ]
      end
    end

    instance_decorator.action_link(
      if: ->() { object.journey_patterns.present? },
      secondary: :show
    ) do |l|
      l.content t('vehicle_journeys.actions.index')
      l.href do
        [
          context[:workbench],
          context[:referential],
          object,
          :vehicle_journeys
        ]
      end
    end

    instance_decorator.action_link(
      secondary: :show,
      policy: :duplicate
    ) do |l|
      l.content t('routes.duplicate.title')
      l.method :post
      l.href do
        h.duplicate_workbench_referential_line_route_path(
          context[:workbench],
          context[:referential],
          context[:line],
          object
        )
      end
    end

    instance_decorator.action_link(
      secondary: :show,
      policy: :create_opposite,
      if: ->{h.has_feature?(:create_opposite_routes)}
    ) do |l|
      l.content t('routes.create_opposite.title')
      l.method :post
      l.disabled { object.opposite_route.present? }
      l.href do
        h.duplicate_workbench_referential_line_route_path(
          context[:workbench],
          context[:referential],
          context[:line],
          object,
          opposite: true
        )
      end
    end

    instance_decorator.destroy_action_link do |l|
      l.data {{ confirm: h.t('routes.actions.destroy_confirm') }}
    end
  end

  def policy_parent
    context[:referential]
  end
end
