# frozen_string_literal: true

class EquipementsController < Chouette::TopologicReferentialController
  defaults resource_class: Equipement

  before_action :equipement_params, only: %i[create update]

  respond_to :html

  def index
    index! do |format|
      format.html do
        @equipements = EquipementDecorator.decorate(
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
      @equipement = @equipement.decorate context: { workbench: workbench }
    end
  end

  protected

  alias equipement resource

  def scope
    @scope ||= workbench.shape_referential.equipements
  end

  def search
    @search ||= Search::Equipement.from_params(params, workbench: workbench)
  end

  def collection
    @collection ||= search.search scope
  end

  private

  def equipement_params
    @equipement_params ||= params.require(:equipement).permit(
      :name,
      :stop_area_id,
      :shape_provider_id,
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
