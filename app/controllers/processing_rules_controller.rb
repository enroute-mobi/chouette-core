class ProcessingRulesController < ChouetteController
  include ApplicationHelper
  include PolicyChecker

	defaults :resource_class => ProcessingRule

  belongs_to :workbench, :workgroup, polymorphic: true

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
            workgroup: workgroup,
            parent: parent
          }
        )
      end
    end
  end

  def get_processables
    payload = get_processables_params.merge(parent: parent)
    render json: { processables: ProcessingRules::GetProcessables.call(payload) }
  end

  protected

  alias processing_rule resource

  def collection
    ProcessingRules::GetCollection.call(parent).paginate(page: params[:page], per_page: 30)  
  end

  private

  def workbench
    @workbench ||= parent.is_a?(Workbench) ? parent : nil
  end

  def workgroup
    @workgroup ||= parent.is_a?(Workbench) ? parent.workgroup : parent
  end

  def decorate_processing_rule
    object = processing_rule rescue build_resource
    @processing_rule = ProcessingRuleDecorator.decorate(
      object,
      context: {
        parent: parent
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
      target_workbenches: []
		)
  end

  def get_processables_params
    params.require(:search).permit(:query, :processable_type).tap do |params|
      params.require(:processable_type)
    end
  end
end
