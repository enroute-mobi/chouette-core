# frozen_string_literal: true

class WorkgroupControlListRunsController < Chouette::WorkgroupController
  include ApplicationHelper

  defaults resource_class: Control::List::Run

  defaults collection_name: 'control_list_runs', instance_name: 'control_list_run'

  before_action :init_facade, only: %i[show]

  respond_to :html, :json

  def index
    index! do |format|
      format.html do
        redirect_to params.merge(page: 1) if collection.out_of_bounds?

        @control_list_runs = WorkgroupControlListRunDecorator.decorate(
          collection,
          context: {
            workgroup: workgroup
          }
        )
      end
    end
  end

  protected

  alias control_list_run resource

  def scope
    workgroup.control_list_runs
  end

  def search
    @search ||= Search.from_params(params, workgroup: workgroup)
  end

  def collection
    @collection ||= search.search(scope)
  end

  private

  class Search < Search::Operation
    attribute :referential_name

    def query(scope)
      super.referential_name(referential_name)
    end

    def query_class
      Query::ControlListRun
    end
  end

  def init_facade
    @facade ||= begin
      OperationRunFacade.new(control_list_run, workbench_for_resource(control_list_run))
    end
  end

  alias facade init_facade

  helper_method :facade
end
