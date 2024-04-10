# frozen_string_literal: true

class FootnotesController < Chouette::ReferentialController
  defaults resource_class: Chouette::Footnote

  belongs_to :line, parent_class: Chouette::Line

  def edit_all
    @footnotes = footnotes
    @line = line
  end

  def update_all
    line.update(line_params)
    redirect_to workbench_referential_line_footnotes_path(current_workbench, @referential, @line)
  end

  protected

  alias_method :footnotes, :collection
  alias_method :line, :parent
  alias resource collection

  private

  def line_params
    params.require(:line).permit(
      { footnotes_attributes: [ :code, :label, :_destroy, :id ] } )
  end
end
