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
class SearchesController < ApplicationController
  before_action :workbench

  # List Saved Search of given type
  # /workbenches/<workbench_id>/<parent_resources>/searches
  def index
    @search = search_class.new(workbench: workbench)
  end

  def show
    @search = saved_searches.find(params[:id]).search
    render :index
  end

  def create
    @search = search_class.from_params(params, workbench: workbench)

    if @search.valid?
      saved_search = saved_searches.create(
        name: params[:search][:name],
        description: params[:search][:description],
        creator: current_user.name,
        search_attributes: @search.attributes
      )
      @search = saved_search.search
    end

    render :index
  end

  def update
    @search = search_class.from_params(params, workbench: workbench)
    
    if @search.valid?
      saved_search = saved_searches.find(params[:id])
      saved_search.update(
        name: params[:search][:name], 
        description: params[:search][:description], 
        search_attributes: @search.attributes
      )

      @search = saved_search.search
    end

    render :index
  end

  def destroy
    saved_searches.find(params[:id]).destroy
    redirect_to workbench_stop_area_referential_searches_path(workbench, parent_resources: parent_resources)
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
    @saved_searches ||= workbench.saved_searches.for(search_class).order(:name)
  end
  helper_method :saved_searches

  def workbench
    @workbench ||= current_organisation.workbenches.find(params[:workbench_id])
  end
end
