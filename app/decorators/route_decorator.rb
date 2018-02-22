class RouteDecorator < AF83::Decorator
  decorates Chouette::Route

  # Action links require:
  #   context: {
  #     referential: ,
  #     line:
  #   }

  set_scope { [context[:referential], context[:line]] }

  with_instance_decorator do |instance_decorator|
    instance_decorator.show_action_link

    instance_decorator.edit_action_link

    instance_decorator.action_link(
      if: ->() { object.stop_points.any? },
      secondary: :show
    ) do |l|
      l.content h.t('journey_patterns.actions.index')
      l.href do
        [
          context[:referential],
          context[:line],
          object,
          :journey_patterns_collection
        ]
      end
    end

    instance_decorator.action_link(
      if: ->() { object.journey_patterns.present? },
      secondary: :show
    ) do |l|
      l.content h.t('vehicle_journeys.actions.index')
      l.href do
        [
          context[:referential],
          context[:line],
          object,
          :vehicle_journeys
        ]
      end
    end

    instance_decorator.action_link secondary: :show do |l|
      l.content h.t('vehicle_journey_exports.new.title')
      l.href do
        h.referential_line_route_vehicle_journey_exports_path(
          context[:referential],
          context[:line],
          object,
          format: :zip
        )
      end
    end

    instance_decorator.action_link(
      secondary: :show,
      policy: :duplicate
    ) do |l|
      l.content h.t('routes.duplicate.title')
      l.href do
        h.duplicate_referential_line_route_path(
          context[:referential],
          context[:line],
          object
        )
      end
    end

    instance_decorator.destroy_action_link do |l|
      l.data confirm: h.t('routes.actions.destroy_confirm')
    end
  end
end
