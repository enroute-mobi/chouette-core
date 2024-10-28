# frozen_string_literal: true

class LineGroupsController < Chouette::LineReferentialController
  include ApplicationHelper

  defaults resource_class: LineGroup

  before_action :line_group_params, only: %i[create update]

  respond_to :html, :xml, :json, :geojson

  def index
    index! do |format|
      format.html do
        @line_groups = LineGroupDecorator.decorate(
          collection,
          context: {
            workbench: workbench
          }
        )
      end
    end
  end

  protected

  alias line_group resource

  def resource
    get_resource_ivar || set_resource_ivar(scope.find_by(id: params[:id]).decorate(context: { workbench: workbench }))
  end

  def build_resource
    get_resource_ivar || set_resource_ivar(
      end_of_association_chain.send(method_for_build, *resource_params).decorate(context: { workbench: workbench })
    )
  end

  def scope
    line_referential.line_groups
  end

  def search
    @search ||= Search::LineGroup.from_params(params, workbench: workbench)
  end

  def collection
    @collection ||= search.search scope
  end

  private

  def line_group_params
    @line_group_params ||= params.require(:line_group).permit(
      :line_provider_id,
      :name,
      :short_name,
      :description,
      line_ids: [],
      codes_attributes: %i[id code_space_id value _destroy]
    )
  end
end
