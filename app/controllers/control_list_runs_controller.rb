class ControlListRunsController < ChouetteController
  include ApplicationHelper
  include PolicyChecker

  defaults :resource_class => Control::List::Run

  before_action :decorate_control_list_run, only: %i[show new edit]
  before_action :select_referentials, only: %i{new create}

  before_action :init_facade, only: %i[show]

	belongs_to :workbench
	belongs_to :control_list, optional: true, collection_name: :control_lists_shared_with_workgroup

  respond_to :html, :json

  def index
    index! do |format|
      format.html do
        redirect_to params.merge(:page => 1) if collection.out_of_bounds?

        @control_list_runs = ControlListRunDecorator.decorate(
          collection,
          context: {
            workbench: @workbench
          }
        )
      end
    end
  end

  def create
    create! do |success, failure|
      failure.html do
        @control_list_run = ControlListRunDecorator.decorate(@control_list_run, context: { workbench: workbench })

        render 'new'
      end

			success.html do
        @control_list_run.enqueue
        redirect_to workbench_control_list_run_path(workbench, @control_list_run)
      end
    end
  end

  protected

  alias control_list parent
  alias control_list_run resource

  def build_resource
    super.tap do |control_list_run|
      control_list_run.workbench = workbench
      control_list_run.build_with_original_control_list
    end
  end

  def scope
   workbench.control_list_runs
  end

  def search
    @search ||= Search.new(scope, params)
  end

  class Search < Search::Operation
    def query_class
      Query::ControlListRun
    end
  end
  delegate :collection, to: :search

  private

  def init_facade
    object = control_list_run rescue Control::List::Run.new(workbench: workbench)
    display_referential_links = object.referential.present? && policy(object.referential).show?
    
    @facade ||= OperationRunFacade.new(object, display_referential_links)
  end

  alias facade init_facade

  helper_method :facade

  def decorate_control_list_run
    object = control_list_run rescue build_resource
    @control_list_run = ControlListRunDecorator.decorate(
      object,
      context: {
        workbench: workbench,
				control_list: control_list
      }
    )
  end

	def workbench
		@workbench ||= Workbench.find(params[:workbench_id])
	end

  def select_referentials
    # TODO: Replace by Control::List::Run.candidate_referentials
    @referentials ||= workbench.referentials.editable.to_a.tap do |referentials|
      referentials << workbench.output&.current
      referentials << workbench.workgroup.output&.current if workbench.workgroup.owner == current_user.organisation
    end.compact
  end

	def control_list_run_params
		params
      .require(:control_list_run)
      .permit(:name, :original_control_list_id, :referential_id)
      .with_defaults(creator: current_user.name)
      .delete_if { |_,v| v.blank? }
	end
end
