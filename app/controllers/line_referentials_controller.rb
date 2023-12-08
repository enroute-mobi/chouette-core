# frozen_string_literal: true

class LineReferentialsController < Chouette::WorkbenchController
  belongs_to :workbench
  defaults resource_class: LineReferential, singleton: true

  def show
    show! do
      @line_referential = LineReferentialDecorator.decorate(@line_referential, context: { workbench: @workbench })
    end
  end
end
