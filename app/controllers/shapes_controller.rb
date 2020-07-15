class ShapesController < ChouetteController
  # FIXME required by page_tile helper (?!)
  defaults :resource_class => Shape

  belongs_to :workbench
  belongs_to :shape_referential, singleton: true

end
