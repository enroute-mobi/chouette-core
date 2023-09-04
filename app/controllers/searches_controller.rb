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
    Rails.logger.debug params.inspect
    Rails.logger.debug [parent_resources, parent_resource, search_class_name, search_class]

    @search = search_class.new(nil)
  end

  def show
    @search = saved_searches.find(params[:id]).search(nil)
    render :index
  end

  def create
    @search = search_class.new(nil, params)

    Rails.logger.debug @search.inspect

    if @search.valid?
      saved_search = saved_searches.create name: params[:search][:name], description: params[:search][:description], search_attributes: @search.meuh_attributes
      Rails.logger.debug [saved_search, saved_search.errors].inspect
      @search = saved_search.search(nil)
    end

    render :index
  end

  def update
    @search = search_class.new(nil, params)
    
    if @search.valid?
      saved_search = saved_searches.find(params[:id])
      saved_search.update name: params[:search][:name], description: params[:search][:description], search_attributes: @search.meuh_attributes

      @search = saved_search.search(nil)
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
