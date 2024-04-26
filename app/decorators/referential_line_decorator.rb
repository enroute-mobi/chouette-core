class ReferentialLineDecorator < AF83::Decorator
  decorates Chouette::Line

  set_scope { [context[:workbench], context[:referential]] }

  with_instance_decorator do |instance_decorator|
    instance_decorator.show_action_link

    instance_decorator.action_link secondary: true do |l|
      l.content { Chouette::Line.tmf(:footnotes) }
      l.href { h.workbench_referential_line_footnotes_path(context[:workbench], context[:referential], object) }
    end

    instance_decorator.action_link secondary: true do |l|
      l.content t('routing_constraint_zones.index.title')
      l.href do
        h.workbench_referential_line_routing_constraint_zones_path(context[:workbench], context[:referential], object)
      end
    end

    instance_decorator.action_link(
      if: ->() { check_policy(:create, Chouette::Route, object: context[:referential]) },
      secondary: true
    ) do |l|
      l.content t('routes.actions.new')
      l.href { h.new_workbench_referential_line_route_path(context[:workbench], context[:referential], object) }
    end
  end
end
