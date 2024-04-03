# frozen_string_literal: true

# Manage ProcessingRule::Workbench on /workbenches/:id/processing_rules
class ProcessingRulesController < Chouette::WorkbenchController
  defaults resource_class: ProcessingRule::Workbench,
           route_instance_name: 'processing_rule_workbench',
           route_collection_name: 'processing_rule_workbenches'

  respond_to :html

  before_action only: :index do
    redirect_to params.merge(only_path: true, page: 1) if collection.out_of_bounds?
  end

  protected

  alias processing_rule resource

  def collection
    @processing_rules ||= decorate(workbench.processing_rules.paginate(page: params[:page], per_page: 30)) # rubocop:disable Naming/MemoizedInstanceVariableName(RuboCop)
  end

  def resource
    @processing_rule ||= decorate(workbench.processing_rules.find(params[:id])) # rubocop:disable Naming/MemoizedInstanceVariableName(RuboCop)
  end

  def build_resource
    @processing_rule ||= decorate(workbench.processing_rules.build(*resource_params)) # rubocop:disable Naming/MemoizedInstanceVariableName(RuboCop)
  end

  def decorate(processing_rule)
    ProcessingRuleDecorator.decorate(
      processing_rule,
      context: {
        workbench: workbench
      }
    )
  end

  private

  def processing_rule_params
    params.require(:processing_rule).permit(
      :processable_type,
      :control_list_id,
      :macro_list_id,
      :operation_step
    )
  end
end
