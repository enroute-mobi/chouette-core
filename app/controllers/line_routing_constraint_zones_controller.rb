# frozen_string_literal: true

class LineRoutingConstraintZonesController < Chouette::LineReferentialController
  include ApplicationHelper

  defaults :resource_class => LineRoutingConstraintZone

  before_action :decorate_line_routing_constraint_zone, only: %i[show new edit]

  respond_to :html, :json

  def index # rubocop:disable Metrics/MethodLength
    index! do |format|
      format.html {
        if collection.out_of_bounds?
          redirect_to params.merge(:page => 1)
        end

        @line_routing_constraint_zones = LineRoutingConstraintZoneDecorator.decorate(
          @line_routing_constraint_zones,
          context: {
            workbench: workbench
          }
        )
      }
      format.json
    end
  end

  protected

  alias :line_routing_constraint_zone :resource

  def collection
    @line_routing_constraint_zones = parent.line_routing_constraint_zones.paginate(page: params[:page], per_page: 30)
  end

  private

  def decorate_line_routing_constraint_zone
    object = line_routing_constraint_zone rescue build_resource
    @line_routing_constraint_zone = LineRoutingConstraintZoneDecorator.decorate(
      object,
      context: {
        workbench: workbench
      }
    )
  end

  def line_routing_constraint_zone_params
    params.require(:line_routing_constraint_zone).permit(
      :name,
      :created_at,
      :updated_at,
      lines: [],
      stop_areas: [],
      codes_attributes: [:id, :code_space_id, :value, :_destroy]
    )
  end

  Policy::Authorizer::Controller.for(self, Policy::Authorizer::Legacy)
end
