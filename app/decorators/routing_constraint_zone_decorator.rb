class RoutingConstraintZoneDecorator < AF83::Decorator
  decorates Chouette::RoutingConstraintZone

  set_scope { [context[:workbench], context[:referential], context[:line]] }

  # Action links require:
  #   context: {
  #     referential: ,
  #     line:
  #   }

  create_action_link(
    if: ->() {
      check_policy(:create) &&
        context[:referential].organisation == h.current_organisation &&
        context[:line].routes.with_at_least_three_stop_points.length > 0
    }
  )

  with_instance_decorator do |instance_decorator|
    instance_decorator.show_action_link
    instance_decorator.edit_action_link

    instance_decorator.action_link secondary: :show, if: ->{ object.opposite_zone.nil? } do |l|
      l.content  t('routing_constraint_zones.actions.create_opposite_zone')
      l.href     { [:new, *scope, :routing_constraint_zone, opposite_zone_id: object.id] }
      l.disabled { !object.can_create_opposite_zone? }
    end

    instance_decorator.action_link secondary: :show, if: ->{ object.opposite_zone.present? } do |l|
      l.content  t('routing_constraint_zones.actions.opposite_zone')
      l.href     { [*scope, object.opposite_zone] }
    end

    instance_decorator.destroy_action_link do |l|
      l.data {{ confirm: h.t('routing_constraint_zones.actions.destroy_confirm') }}
    end
  end
end
