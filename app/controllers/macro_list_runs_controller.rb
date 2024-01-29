# frozen_string_literal: true

class MacroListRunsController < Chouette::WorkbenchController
  include ApplicationHelper
  include PolicyChecker

  defaults resource_class: Macro::List::Run

  before_action :decorate_macro_list_run, only: %i[show new edit]
  before_action :select_referentials, only: %i[new create]

  before_action :init_facade, only: %i[show]

  belongs_to :macro_list, optional: true

  respond_to :html, :json

  def index
    index! do |format|
      format.html do
        redirect_to params.merge(page: 1) if collection.out_of_bounds?

        @macro_list_runs = MacroListRunDecorator.decorate(
          collection,
          context: { workbench: workbench }
        )
      end
    end
  end

  def create
    create! do |success, failure|
      failure.html do
        @macro_list_run = MacroListRunDecorator.decorate(@macro_list_run, context: { workbench: workbench })

        render 'new'
      end

      success.html do
        @macro_list_run.enqueue
        redirect_to workbench_macro_list_run_path(workbench, @macro_list_run)
      end
    end
  end

  protected

  alias macro_list_run resource

  def macro_list
    # Ensure parent is loaded
    association_chain

    parent if parent.is_a?(Macro::List)
  end

  def build_resource
    super.tap do |macro_list_run|
      macro_list_run.build_with_original_macro_list
      macro_list_run.workbench = workbench
    end
  end

  def scope
    workbench.macro_list_runs
  end

  def search
    @search ||= Search.from_params(params)
  end

  class Search < Search::Operation
    def query_class
      Query::MacroListRun
    end
  end

  def collection
    @collection ||= search.search(scope)
  end

  private

  def init_facade
    object = begin
      macro_list_run
    rescue StandardError
      Macro::List::Run.new(workbench: workbench)
    end
    @facade ||= OperationRunFacade.new(object, current_workbench)
  end

  alias facade init_facade

  helper_method :facade

  def decorate_macro_list_run
    object = begin
      macro_list_run
    rescue StandardError
      build_resource
    end
    @macro_list_run = MacroListRunDecorator.decorate(
      object,
      context: {
        workbench: workbench,
        macro_list: macro_list
      }
    )
  end

  def select_referentials
    @referentials ||= workbench.referentials.editable
  end

  def macro_list_run_params
    params
      .require(:macro_list_run)
      .permit(:name, :original_macro_list_id, :referential_id)
      .with_defaults(creator: current_user.name)
      .delete_if { |_, v| v.blank? }
  end
end
