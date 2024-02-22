# frozen_string_literal: true

class StopAreaRoutingConstraintsController < Chouette::StopAreaReferentialController
  include ApplicationHelper

  requires_feature :stop_area_routing_constraints

  defaults :resource_class => StopAreaRoutingConstraint

  respond_to :html, :json

  def index # rubocop:disable Metrics/MethodLength
    index! do |format|
      format.html {
        if collection.out_of_bounds?
          redirect_to params.merge(:page => 1)
        end

        @stop_area_routing_constraints = StopAreaRoutingConstraintDecorator.decorate(
          @stop_area_routing_constraints,
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

  protected

  alias_method :stop_area, :resource

  def build_resource
    get_resource_ivar || super.tap do |routing_constraint|
      routing_constraint.stop_area_provider ||= workbench.default_stop_area_provider
    end
  end

  def collection
    scope = parent.stop_area_routing_constraints
    @q = scope.ransack(params[:q])
    @with_stop = params[:q] && params[:q][:with_stop] && Chouette::StopArea.find(params[:q][:with_stop])
    @stop_area_routing_constraints ||=
      begin
        if sort_column == 'from_name'
          stop_area_routing_constraints = @q.result.joins('INNER JOIN public.stop_areas froms ON froms.id = stop_area_routing_constraints.from_id').order("froms.name #{sort_direction}")
        elsif sort_column == 'to_name'
          stop_area_routing_constraints = @q.result.joins('INNER JOIN public.stop_areas tos ON tos.id = stop_area_routing_constraints.to_id').order("tos.name #{sort_direction}")
        else
          stop_area_routing_constraints = @q.result.order("both_way #{sort_direction}")
        end
        stop_area_routing_constraints = stop_area_routing_constraints.paginate(:page => params[:page])
        stop_area_routing_constraints
      end
  end

  private

  def sort_column
    params[:sort].presence || 'from_name'
  end

  def sort_direction
    %w[asc desc].include?(params[:direction]) ?  params[:direction] : 'asc'
  end

  def stop_area_routing_constraint_params
    params.require(:stop_area_routing_constraint).permit(:from_id, :to_id, :both_way)
  end
end
