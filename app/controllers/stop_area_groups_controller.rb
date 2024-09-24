# frozen_string_literal: true

class StopAreaGroupsController < Chouette::StopAreaReferentialController
  include ApplicationHelper

  defaults resource_class: StopAreaGroup

  before_action :stop_area_group_params, only: %i[create update]

  respond_to :html, :xml, :json, :geojson

  def index
    index! do |format|
      format.html do
        @stop_area_groups = StopAreaGroupDecorator.decorate(
          collection,
          context: {
            workbench: workbench
          }
        )
      end
    end
  end

  protected

  alias stop_area_group resource

  def resource
    get_resource_ivar || set_resource_ivar(scope.find_by(id: params[:id]).decorate(context: { workbench: workbench }))
  end

  def build_resource
    get_resource_ivar || set_resource_ivar(
      end_of_association_chain.send(method_for_build, *resource_params).decorate(context: { workbench: workbench })
    )
  end

  def scope
    stop_area_referential.stop_area_groups
  end

  def search
    @search ||= Search::StopAreaGroup.from_params(params, workbench: workbench)
  end

  def collection
    @collection ||= search.search scope
  end

  private

  def stop_area_group_params
    @stop_area_group_params ||= params.require(:stop_area_group).permit(
      :stop_area_provider_id,
      :name,
      :description,
      stop_area_ids: [],
      codes_attributes: %i[id code_space_id value _destroy]
    )
  end
end
