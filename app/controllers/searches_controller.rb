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
  before_action :workgroup
  before_action :workbench

  before_action :find_saved_search, only: %i[update destroy]

  # List Saved Search of given type
  # /workbenches/<workbench_id>/<parent_resources>/searches
  def index
    @search = search_class.new(search_context)
  end

  def show
    @search = saved_searches.find(params[:id]).search
    render :index
  end

  def create
    @search = search_class.from_params(params, search_context)

    @saved_search = saved_searches.create(
      name: params[:search][:saved_name],
      description: params[:search][:saved_description],
      creator: current_user.name,
      search_attributes: @search.attributes
    )
    @search = @saved_search.search

    render :index
  end

  def update
    @search = search_class.from_params(params, search_context)

    if @search.valid?
      @saved_search.update(
        name: params[:search][:saved_name],
        description: params[:search][:saved_description],
        search_attributes: @search.attributes
      )

      @search = @saved_search.search
    end

    render :index
  end

  def destroy
    @saved_search.destroy

    redirect_to [saved_search_parent, :searches, { parent_resources: parent_resources }]
  end

  private

  def parent_resources
    params[:parent_resources]
  end
  helper_method :parent_resources

  def parent_resource
    parent_resources.singularize
  end

  def search_class
    @search_class ||= ::Search::Save.search_class_name(saved_search_parent, parent_resource).constantize
  end

  def saved_searches
    @saved_searches ||= saved_search_parent.saved_searches.for(search_class).order(:name)
  end
  helper_method :saved_searches

  def find_saved_search
    @saved_search = saved_searches.find(params[:id])
  end

  def workgroup
    @workgroup ||= current_user.workgroups.find(params[:workgroup_id]) if params[:workgroup_id]
  end

  def current_workgroup
    workgroup
  rescue ActiveRecord::RecordNotFound
    nil
  end

  def workbench
    @workbench ||= current_user.workbenches.find(params[:workbench_id]) if params[:workbench_id]
  end

  def current_workbench
    workbench
  rescue ActiveRecord::RecordNotFound
    nil
  end

  def saved_search_parent
    workbench || workgroup
  end

  def search_context
    { saved_search_parent.class.name.underscore.to_sym => saved_search_parent }
  end
end
