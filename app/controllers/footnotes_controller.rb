# frozen_string_literal: true

class FootnotesController < Chouette::ReferentialController
  defaults resource_class: Chouette::Footnote

  belongs_to :line, parent_class: Chouette::Line

  # rubocop:disable Rails/LexicallyScopedActionFilter
  before_action :authorize_resource, except: %i[new create index show edit_all update_all]
  before_action :authorize_resource_class, only: %i[new create edit_all update_all]
  # rubocop:enable Rails/LexicallyScopedActionFilter

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

  Policy::Authorizer::Controller.for(self, Policy::Authorizer::Legacy)
end
