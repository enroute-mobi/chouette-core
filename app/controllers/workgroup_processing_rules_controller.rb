# frozen_string_literal: true

# Manage ProcessingRule::Workgroup on /workgroups/:id/processing_rules
class WorkgroupProcessingRulesController < Chouette::WorkgroupController
  defaults resource_class: ProcessingRule::Workgroup,
           route_instance_name: 'processing_rule_workgroup',
           route_collection_name: 'processing_rule_workgroups'

  respond_to :html

  before_action only: :index do
    redirect_to params.merge(only_path: true, page: 1) if collection.out_of_bounds?
  end

  protected

  def collection
    @processing_rules ||= decorate(workgroup.processing_rules.paginate(page: params[:page], per_page: 30)) # rubocop:disable Naming/MemoizedInstanceVariableName(RuboCop)
  end
  # Overrides ApplicationController#decorated_collection (which uses a dummy default naming)
  alias decorated_collection collection

  def resource
    @processing_rule ||= decorate(workgroup.processing_rules.find(params[:id])) # rubocop:disable Naming/MemoizedInstanceVariableName(RuboCop)
  end
  alias processing_rule resource

  def build_resource
    @processing_rule ||= decorate(workgroup.processing_rules.build(*resource_params)) # rubocop:disable Naming/MemoizedInstanceVariableName(RuboCop)
  end

  def decorate(processing_rule)
    ProcessingRuleWorkgroupDecorator.decorate(
      processing_rule,
      context: {
        workgroup: workgroup
      }
    )
  end

  private

  def workgroup_processing_rule_params
    params.require(:processing_rule).permit(
      :processable_class_name,
      :operation_step,
      :control_list_id,
      processing_setup: [
        :type,
        :ruleset, :include_schema, :schema_version, :token # FlamingoValidation
      ],
      target_workbenches: [],
      excluded_workbenches: []
    ).tap do |params|
      processable_class_name = params.delete(:processable_class_name)
      if processable_class_name.in?(ProcessingRule::Workgroup.processable_type.values)
        params[:processable_type] = processable_class_name
      else
        params[:processing_setup] ||= ActionController::Parameters.new.permit!
        params[:processing_setup][:type] = processable_class_name
      end
    end
  end
end
