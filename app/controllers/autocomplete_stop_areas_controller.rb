class AutocompleteStopAreasController < ChouetteController
  respond_to :json, :only => [:index, :children, :parent, :physicals]

  include ReferentialSupport

  def around
    stop_area   = initial_scope.find params[:id]
    @stop_areas = stop_area.around(referential.stop_areas.where(area_type: params[:target_type]), 300)
  end

  protected

  def initial_scope
    parent = referential.workbench.present? ? referential.workbench : referential
    parent_scope = parent.stop_areas
    parent_scope.where(deleted_at: nil)
  end

  def collection
    scope = initial_scope
    scope = scope.physical if physical_filter?
    if target_type?
      scope = scope.where(area_type: params[:target_type])
      scope = scope.possible_parents if relation_parent?
      scope = scope.possible_parents if relation_children?
    end
    if search_scope&.to_s == "route_editor"
      scope = scope.where(kind: :non_commercial).or(scope.where(area_type: referential.stop_area_referential.available_stops)) unless current_user.organisation.has_feature?("route_stop_areas_all_types")
    end
    args = [].tap{|arg| 4.times{arg << "%#{params[:q]}%"}}
    @stop_areas = scope.where("unaccent(stop_areas.name) ILIKE unaccent(?) OR unaccent(stop_areas.city_name) ILIKE unaccent(?) OR stop_areas.registration_number ILIKE ? OR stop_areas.objectid ILIKE ?", *args).limit(50)
    @stop_areas
  end

  def target_type?
    params.has_key?(:target_type)
  end

  def search_scope
    params[:scope]
  end

  def relation_parent?
    params[ :relation ] == "parent"
  end

  def relation_children?
    params[ :relation ] == "children"
  end

  def physical_filter?
    params[:filter] == "physical"
  end
end
