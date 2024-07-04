# frozen_string_literal: true

# Manage Search::Save models under a given model Controller
#
# Example:
#
#   resources :stop_areas
#   resources :searches, path: ':parent_resources/searches', controller: SearchesController do
#     # ...
#   end
#
class SearchesController < Chouette::UserController
  before_action :workbench
  before_action :workgroup

  # List Saved Search of given type
  # /workbenches/<workbench_id>/<parent_resources>/searches
  def index
    @search = search_class.new(workbench: workbench || workgroup.owner_workbench)
  end

  def show
    @search = saved_searches.find(params[:id]).search
    render :index
  end

  def create
    @search = search_class.from_params(params, workbench: workbench || workgroup.owner_workbench)

    saved_search = saved_searches.create(
      name: params[:search][:saved_name],
      description: params[:search][:saved_description],
      creator: current_user.name,
      search_attributes: @search.attributes
    )
    @search = saved_search.search

    render :index
  end

  def update
    @search = search_class.from_params(params, workbench: workbench || workgroup.owner_workbench)

    if @search.valid?
      saved_search = saved_searches.find(params[:id])
      saved_search.update(
        name: params[:search][:saved_name],
        description: params[:search][:saved_description],
        search_attributes: @search.attributes
      )

      @search = saved_search.search
    end

    render :index
  end

  def destroy
    saved_search = saved_searches.find(params[:id])

    saved_search.destroy

    if workbench
      redirect_to workbench_searches_path(workbench, parent_resources: saved_search.search_type['Search::'.length..].underscore.pluralize)
    else
      redirect_to workgroup_searches_path(workgroup, parent_resources: saved_search.search_type['Search::'.length..].underscore.pluralize)
    end
  end

  private

  def parent_resources
    params[:parent_resources]
  end
  helper_method :parent_resources

  def parent_resource
    parent_resources.singularize
  end

  def search_class_name
    "Search::#{parent_resource.classify}"
  end

  def search_class
    search_class_name.constantize
  end

  def saved_searches
    @saved_searches ||= (workbench || workgroup.owner_workbench).saved_searches.for(search_class).order(:name)
  end
  helper_method :saved_searches

  def workbench
    @workbench ||= current_user.workbenches.find(params[:workbench_id]) if params[:workbench_id]
  end

  def workgroup
    @workgroup ||= current_user.workgroups.find(params[:workgroup_id]) if params[:workgroup_id]
  end
end
