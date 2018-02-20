class AutocompleteTimeTablesController < ChouetteController
  respond_to :json, :only => [:index]
  before_action :switch_referential

  include ReferentialSupport

  def switch_referential
    Apartment::Tenant.switch!(referential.slug)
  end

  def referential
    @referential ||= Referential.find params[:referential_id]
  end

  protected

  def select_time_tables
    scope = params[:source_id] ? referential.time_tables.where("time_tables.id != ?", params[:source_id]) : referential.time_tables
    if params[:route_id]
      scope = scope.joins(vehicle_journeys: :route).where( "routes.id IN (#{params[:route_id]})")
    end
    scope.distinct
  end

  def split_params! search
    params[:q][search] = params[:q][search].split(" ") if params[:q] && params[:q][search]
  end

  def collection
    split_params! :comment_or_objectid_cont_any
    @time_tables = select_time_tables.search(params[:q]).result.paginate(page: params[:page])
  end
end
