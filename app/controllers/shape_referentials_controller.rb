class ShapeReferentialsController < ChouetteController
  # FIXME required by page_tile helper (?!)
  defaults :resource_class => ShapeReferential

  defaults :singleton => true
  belongs_to :workbench
end
