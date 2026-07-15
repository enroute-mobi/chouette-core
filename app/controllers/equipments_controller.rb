# frozen_string_literal: true

class EquipmentsController < Chouette::StopAreaReferentialController
  defaults resource_class: Equipment

  before_action :equipment_params, only: %i[create update]

  respond_to :html

  def index
    index! do |format|
      format.html do
        @equipments = EquipmentDecorator.decorate(
          collection,
          context: {
            workbench: workbench
          }
        )
      end
    end
  end

  def show
    show! do
      @equipment = @equipment.decorate context: { workbench: workbench }
    end
  end

  protected

  alias equipment resource

  def scope
    stop_area_referential.equipments
  end

  def search
    @search ||= Search::Equipment.from_params(params, workbench: workbench)
  end

  def collection
    @collection ||= search.search scope
  end

  private

  def equipment_params
    @equipment_params ||= params.require(:equipment).permit(
      :objectid,
      :name,
      :stop_area_id,
      :stop_area_provider_id,
      :public_code,
      :fixed,
      :out_of_order,
      :mobility_impaired_accessibility,
      :wheelchair_accessibility,
      :step_free_accessibility,
      :escalator_free_accessibility,
      :lift_free_accessibility,
      :audible_signals_availability,
      :visual_signs_availability,
      :description,
      codes_attributes: %i[id code_space_id value _destroy]
    )
  end
end
