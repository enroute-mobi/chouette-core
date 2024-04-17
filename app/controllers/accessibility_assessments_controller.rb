# frozen_string_literal: true

class AccessibilityAssessmentsController < Chouette::ReferentialController
  include ApplicationHelper
  include PolicyChecker

  defaults resource_class: AccessibilityAssessment

  def index
    index! do |format|
      format.html do
        @accessibility_assessments = AccessibilityAssessmentDecorator.decorate(
          collection,
          context: {
            workbench: workbench,
            referential: referential
          }
        )
      end
    end
  end

  protected

  alias accessibility_assessment resource

  def scope
    @scope ||= referential.accessibility_assessments
  end

  def resource
    get_resource_ivar || set_resource_ivar(scope.find_by(id: params[:id]).decorate(context: { workbench: workbench, referential: referential }))
  end

  def build_resource
    get_resource_ivar || set_resource_ivar(
      end_of_association_chain.send(method_for_build, *resource_params).decorate(context: { workbench: workbench, referential: referential })
    )
  end

  def collection
    @accessibility_assessments = scope.paginate(page: params[:page], per_page: 30)
  end

  private

  def accessibility_assessment_params
    params.require(:accessibility_assessment).permit(
      :name,
      :mobility_impaired_accessibility,
      :wheelchair_accessibility,
      :step_free_accessibility,
      :escalator_free_accessibility,
      :lift_free_accessibility,
      :audible_signals_availability,
      :visual_signs_availability,
      :accessibility_limitation_description,
      codes_attributes: [:id, :code_space_id, :value, :_destroy],
    )
  end
end
