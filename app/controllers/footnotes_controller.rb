# frozen_string_literal: true

class FootnotesController < Chouette::ReferentialController
  defaults resource_class: Chouette::Footnote

  belongs_to :line, parent_class: Chouette::Line, optional: true

  def index
    index! do |format|
      format.html
      format.json {}
    end
  end

  protected

  def resource
    get_resource_ivar || set_resource_ivar(super.decorate(context: decorator_context))
  end

  def collection
    return @footnotes if @footnotes

    footnotes = (parent || @referential).footnotes
    footnotes = footnotes.includes(line: :company_light) unless parent
    @footnotes = FootnoteDecorator.decorate(
      footnotes.paginate(page: params[:page], per_page: params[:per_page]),
      context: decorator_context
    )
  end

  def parent_for_parent_policy
    @referential
  end

  private

  def footnote_params
    params.require(:footnote).permit(
      :code,
      :label,
      :line_id,
      codes_attributes: %i[id code_space_id value _destroy]
    )
  end

  def decorator_context
    {
      workbench: @workbench,
      referential: @referential
    }.tap do |context|
      context[:line] = parent if parent
    end
  end
end
