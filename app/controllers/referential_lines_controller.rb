# frozen_string_literal: true

class ReferentialLinesController < Chouette::ReferentialController
  include ReferentialSupport
  include PolicyChecker

  defaults :resource_class => Chouette::Line, :collection_name => 'lines', :instance_name => 'line'
  respond_to :html
  respond_to :xml
  respond_to :json
  respond_to :geojson, :only => :show
  respond_to :js, :only => :index

  belongs_to :referential

  def show
    @q = resource.routes.ransack(params[:q])
    @routes = @q.result

    case sort_route_column
    when "stop_points", "journey_patterns"
      left_join = %Q{LEFT JOIN "#{sort_route_column}" ON "#{sort_route_column}"."route_id" = "routes"."id"}

      @routes = @routes.joins(left_join).group(:id).order(Arel.sql("count(#{sort_route_column}.route_id) #{sort_route_direction}"))
    else
      @routes = @routes.order(Arel.sql("lower(#{sort_route_column}) #{sort_route_direction}"))
    end

    @routes = @routes.paginate(page: params[:page], per_page: 10)

    @routes = RouteDecorator.decorate(
      @routes,
      context: {
        referential: referential,
        line: @line
      }
    )

    show! do |format|
      @line = ReferentialLineDecorator.decorate(
        @line,
        context: {
          referential: referential,
          current_organisation: current_organisation
        }
      )
    end
  end

  private

  def sort_route_column
    (@line.routes.column_names + %w{stop_points journey_patterns}).include?(params[:sort]) ? params[:sort] : 'name'
  end
  def sort_route_direction
    %w[asc desc].include?(params[:direction]) ?  params[:direction] : 'asc'
  end

end
