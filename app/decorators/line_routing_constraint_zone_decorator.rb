class LineRoutingConstraintZoneDecorator < AF83::Decorator
  decorates LineRoutingConstraintZone

  set_scope { [ context[:workbench], :line_referential ] }

  create_action_link

  with_instance_decorator do |instance_decorator|
    instance_decorator.crud
  end

  define_instance_method :line_ids_options do
    return [] unless object.line_ids

    Rabl::Renderer.new('autocomplete/lines', Chouette::Line.where(id: object.line_ids), format: :hash, view_path: 'app/views').render
  end
end
