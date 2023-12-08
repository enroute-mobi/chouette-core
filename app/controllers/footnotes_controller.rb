# frozen_string_literal: true

class FootnotesController < Chouette::ReferentialController
  include ReferentialSupport

  before_action :authorize_resource

  defaults resource_class: Chouette::Footnote

  belongs_to :referential do
    belongs_to :line, :parent_class => Chouette::Line
  end

  def edit_all
    @footnotes = footnotes
    @line = line
  end

  def update_all
    line.update(line_params)
    redirect_to referential_line_footnotes_path(@referential, @line)
  end

  protected

  alias_method :footnotes, :collection
  alias_method :line, :parent

  private

  def line_params
    params.require(:line).permit(
      { footnotes_attributes: [ :code, :label, :_destroy, :id ] } )
  end

  def authorize_resource
    authorize resource_class, "#{action_name}?".to_sym
  end
end
