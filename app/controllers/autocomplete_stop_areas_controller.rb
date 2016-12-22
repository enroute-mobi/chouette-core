class AutocompleteStopAreasController < InheritedResources::Base
  respond_to :json, :only => [:index, :children, :parent, :physicals]

  before_action :switch_referential

  def switch_referential
    Apartment::Tenant.switch!(referential.slug)
  end

  def referential
    @referential ||= current_organisation.referentials.find params[:referential_id]
  end

  protected

  def collection
    scope = referential.stop_areas
    scope = scope.physical if physical_filter?
    if target_type?
      scope = scope.where(area_type: params[:target_type])
      scope = scope.possible_parents if relation_parent?
      scope = scope.possible_parents if relation_children?
    end
    args = [].tap{|arg| 3.times{arg << "%#{params[:q]}%"}}
    @stop_areas = scope.where("name ILIKE ? OR registration_number ILIKE ? OR objectid ILIKE ?", *args).limit(50)
    @stop_areas
  end

  def target_type?
    params.has_key?( :target_type)
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
