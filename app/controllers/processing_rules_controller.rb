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

  def add_workgroup_rule
    @processing_rule = ProcessingRuleDecorator.decorate(
      ProcessingRule.new(workgroup_id: workbench.workgroup_id),
      context: {
        workbench: @workbench
      }
    )
  end

  def get_processables
    fetch_params = get_processables_params
    query = fetch_params[:query]&.downcase

    case fetch_params[:processable_type]
    when 'Control::List'
      result = workbench.workgroup.control_lists.where("workbench_id = :workbench_id OR (workbench_id != :workbench_id AND shared IS TRUE)")
    when 'Macro::List'
      result = workbench.macro_lists
    else
      Rails.logger.warn('processable_type not defined when trying to fetch processables')
      result = []
    end

    result = result
      .then { |c| query ? c.where("lower(name) LIKE :query", query: "%#{query}%") : c }
      .select("id, name AS text")

    render json: { processables: result }
  end

  protected

  alias processing_rule resource
  alias workbench parent

  def collection
    is_owner = workbench.workgroup.owner_id == workbench.organisation_id

    @processing_rules = workbench.workgroup.processing_rules
      .then { |collection| is_owner ? collection : collection.where('target_workbench_ids::integer[] @> ARRAY[?]', workbench.id) }
      .or(workbench.processing_rules)
      .paginate(page: params[:page], per_page: 30)    
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
      target_workbenches: []
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
