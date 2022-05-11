class ProcessingRulesController < ChouetteController
  include ApplicationHelper
  include PolicyChecker

	defaults :resource_class => ProcessingRule

  before_action :decorate_processing_rule, only: %i[show new edit]
  after_action :decorate_processing_rule, only: %i[create update]

  belongs_to :workbench

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
            workbench: @workbench,
          }
        )
      end
    end
  end

  def get_processables
    fetch_params = get_processables_params

    result = fetch_params[:processable_type].constantize.where(workbench_id: workbench.id)
    result = result.where("lower(name) LIKE :query", query: "%#{fetch_params[:query].downcase}%") if fetch_params[:query]

    render json: { processables: result.select("id, name AS text") }
  end

  protected

  alias processing_rule resource
  alias workbench parent

  def collection
    scope = workbench.workgroup.owner_id == workbench.organisation_id ? workbench.workgroup : workbench

    @processing_rules = scope.processing_rules.paginate(page: params[:page], per_page: 30)    
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
			:operation_step
		).tap do |params|
			%i[processable_type processable_id operation_step].each { |key| params.require(key) }
		end
  end

  def get_processables_params
    params.require(:search).permit(:query, :processable_type).tap do |params|
      params.require(:processable_type)
    end
  end
end
