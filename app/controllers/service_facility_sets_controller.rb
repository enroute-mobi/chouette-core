# frozen_string_literal: true

class ServiceFacilitySetsController < Chouette::TopologicReferentialController
  defaults resource_class: ServiceFacilitySet

  def index
    index! do |format|
      format.html do
        @service_facility_sets = ServiceFacilitySetDecorator.decorate(
          collection,
          context: {
            workbench: workbench
          }
        )
      end
    end
  end

  protected

  alias service_facility_set resource

  def scope
    @scope ||= workbench.shape_referential.service_facility_sets
  end

  def resource
    super.decorate(context: { workbench: workbench })
  end

  def build_resource
    super.decorate(context: { workbench: workbench })
  end

  def collection
    @service_facility_sets = scope.paginate(page: params[:page], per_page: 30)
  end

  private

  def service_facility_set_params
    params.require(:service_facility_set).permit(
      :name,
      associated_services: [],
      codes_attributes: [:id, :code_space_id, :value, :_destroy],
    )
  end
end