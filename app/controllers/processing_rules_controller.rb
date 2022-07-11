class ProcessingRulesController < ChouetteController
  include ApplicationHelper
  include PolicyChecker

	defaults :resource_class => ProcessingRule

  belongs_to :workbench

  before_action :decorate_processing_rule, only: %i[show new edit create update]

  respond_to :html, :xml, :json

  def index
    index! do |format|
      format.html do
        if collection.out_of_bounds?
          redirect_to params.merge(:page => 1)
        end

        @processing_rules = ProcessingRuleDecorator.decorate(
          collection,
          context: {
            workbench: @workbench
          }
        )
      end
    end
  end

  def add_workgroup_rule
    @processing_rule = ProcessingRuleDecorator.decorate(
      workbench.processing_rules.build(workgroup_rule: true),
      context: {
        workbench: workbench
      }
    )
  end

  def get_processables
    render json: { processables: ProcessingRules::GetProcessables.call(get_processables_params) }
  end

  protected

  alias processing_rule resource
  alias workbench parent

  def collection
    result = workbench.owner? ? workbench.workgroup.processing_rules : workbench.processing_rules

    result.paginate(page: params[:page], per_page: 30)  
  end

  private

  def decorate_processing_rule
    object = processing_rule rescue build_resource
    @processing_rule = ProcessingRuleDecorator.decorate(
      object,
      context: {
        workbench: @workbench
      }
    )
  end

  def processing_rule_params
    params.require(:processing_rule).permit(
			:processable_type,
			:processable_id,
			:operation_step,
      :workbench_id,
      :workgroup_id,
      :workgroup_rule,
      target_workbenches: []
		)
  end

  def get_processables_params
    params.require(:search)
      .permit(
        :query,
        :processable_type,
        :workgroup_rule
      ).with_defaults(workbench: workbench).tap do |params|
      params.require(:processable_type)
      params.require(:workgroup_rule)
    end
  end
end
