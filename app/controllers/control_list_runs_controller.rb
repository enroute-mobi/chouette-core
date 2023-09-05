class ControlListRunsController < ChouetteController
  include ApplicationHelper
  include PolicyChecker

  defaults resource_class: Control::List::Run

  before_action :decorate_control_list_run, only: %i[show new edit]

  before_action :init_facade, only: %i[show]

  belongs_to :workbench
  belongs_to :control_list, optional: true, collection_name: :control_lists_shared_with_workgroup

  respond_to :html, :json

  def index
    index! do |format|
      format.html do
        redirect_to params.merge(page: 1) if collection.out_of_bounds?

        @control_list_runs = ControlListRunDecorator.decorate(
          collection,
          context: { workbench: @workbench }
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

  alias control_list_run resource

  def control_list
    # Ensure parent is loaded
    association_chain

    parent if parent.is_a?(Control::List)
  end

  def workbench
    # Ensure parent is loaded
    association_chain

    @workbench ||= parent.is_a?(Workbench) ? parent : parent&.workbench
  end

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
    @search ||= Search.from_params(params)
  end

  class Search < Search::Operation
    def query_class
      Query::ControlListRun
    end
  end

  def collection
    @collection ||= search.search(scope)
  end

  private

  def init_facade
    object = begin
      control_list_run
    rescue StandardError
      Control::List::Run.new(workbench: workbench)
    end
    display_referential_links = object.referential.present? && policy(object.referential).show?

    @facade ||= OperationRunFacade.new(object, current_workbench, display_referential_links: display_referential_links)
  end

  alias facade init_facade

  helper_method :facade

  def decorate_control_list_run
    object = begin
      control_list_run
    rescue StandardError
      build_resource
    end
    @control_list_run = ControlListRunDecorator.decorate(
      object,
      context: {
        workbench: workbench,
        control_list: control_list
      }
    )
  end

  def control_list_run_params
    params
      .require(:control_list_run)
      .permit(:name, :original_control_list_id, :referential_id)
      .with_defaults(creator: current_user.name)
      .delete_if { |_, v| v.blank? }
  end
end
