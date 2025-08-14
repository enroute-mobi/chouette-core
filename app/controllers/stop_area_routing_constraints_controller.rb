# frozen_string_literal: true

class StopAreaRoutingConstraintsController < Chouette::StopAreaReferentialController
  include ApplicationHelper

  requires_feature :stop_area_routing_constraints

  defaults :resource_class => StopAreaRoutingConstraint

  respond_to :html, :json

  def index # rubocop:disable Metrics/MethodLength
    if (saved_search = saved_searches.find_by(id: params[:search_id]))
      @search = saved_search.search
    end

    index! do |format|
      format.html {
        if collection.out_of_bounds?
          redirect_to params.merge(:page => 1)
        end

        @stop_area_routing_constraints = StopAreaRoutingConstraintDecorator.decorate(
          @stop_area_routing_constraints.includes(
            :stop_area_provider,
            from: :stop_area_referential, # formatted_selection_details needs the referential of the stop area
            to: :stop_area_referential
          ),
          context: {
            workbench: workbench
          }
        )
      }
      format.json
    end
  end

  def show
    show! do |format|
      @stop_area_routing_constraint = @stop_area_routing_constraint.decorate(context: { workbench: workbench })
    end
  end

  def saved_searches
    @saved_searches ||= workbench.saved_searches.for(::Search::StopAreaRoutingConstraint)
  end

  protected

  alias_method :stop_area, :resource

  def scope
    parent.stop_area_routing_constraints
  end

  def search
    @search ||= ::Search::StopAreaRoutingConstraint.from_params(params, workbench: workbench)
  end

  def collection
    @stop_area_routing_constraints ||= search.search(scope) # rubocop:disable Naming/MemoizedInstanceVariableName
  end

  private

  def stop_area_routing_constraint_params
    @stop_area_routing_constraint_params ||= params.require(:stop_area_routing_constraint).permit(
      :from_id,
      :to_id,
      :both_way,
      :stop_area_provider_id
    )
  end
end
