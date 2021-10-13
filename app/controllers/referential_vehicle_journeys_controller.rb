#
# Browse all VehicleJourneys of the Referential
#
class ReferentialVehicleJourneysController < ChouetteController
  include ReferentialSupport
  include RansackDateFilter

  before_action(only: [:index]) { set_date_time_params("time_table", Date, prefix: :time_table) }

  defaults :resource_class => Chouette::VehicleJourney, collection_name: :vehicle_journeys

  belongs_to :referential

  def index
    if params[:q] && params[:q][:route_line_id_eq].present?
      @filtered_line = Chouette::Line.find(params[:q][:route_line_id_eq])
    end

    index! do |format|
      format.html {
        @vehicle_journeys = VehicleJourneyDecorator.decorate(
          @vehicle_journeys,
          context: {
            referential: referential
          }
        )
      }
    end
  end

  private

  def collection
    @q ||= end_of_association_chain
    # We filter as much as as possible BEFORE the expensive queries

    if params[:q] && params[:q][:company_id_eq_any]
      company_ids = params[:q][:company_id_eq_any].delete_if(&:blank?)
      @q = @q.with_companies(company_ids) unless company_ids.empty?
    end
    @q = @q.with_stop_area_ids(params[:q][:stop_area_ids]) if params[:q] && params[:q][:stop_area_ids]
    @q = ransack_period_range(scope: @q, error_message:  t('vehicle_journeys.errors.time_table'), query: :with_matching_timetable, prefix: :time_table)
    @q = @q.select("vehicle_journeys.id", "vehicle_journeys.journey_pattern_id", "vehicle_journeys.route_id", "vehicle_journeys.objectid", "vehicle_journeys.published_journey_name")
    @starting_stop = params[:q] && params[:q][:stop_areas] && params[:q][:stop_areas][:start].present? ? Chouette::StopArea.find(params[:q][:stop_areas][:start]) : nil
    @ending_stop = params[:q] && params[:q][:stop_areas] && params[:q][:stop_areas][:end].present? ? Chouette::StopArea.find(params[:q][:stop_areas][:end]) : nil

    if @starting_stop
      @q =
        unless @ending_stop
          @q.with_stop_area_id(@starting_stop.id)
        else
          @q.with_ordered_stop_area_ids(@starting_stop.id, @ending_stop.id)
        end
    elsif @ending_stop
      @q = @q.with_stop_area_id(@ending_stop.id)
    end

    @q = @q.ransack(params[:q])
    @vehicle_journeys ||= @q.result
    @vehicle_journeys = parse_order @vehicle_journeys
    @all_companies = Chouette::Company.where("id IN (#{@referential.vehicle_journeys.select(:company_id).to_sql})").distinct
    @vehicle_journeys = @vehicle_journeys.paginate page: params[:page], per_page: params[:per_page] || 10
  end

  def parse_order scope
    return scope.order(:published_journey_name) unless params[:sort].present?
    direction = params[:direction] || "asc"
    case params[:sort]
      when "line"
        scope.select('lines.name').order("lines.name #{direction}").joins(route: :line)
      when "route"
        scope.select('routes.name').order("routes.name #{direction}").joins(:route)
      when "departure_time"
        scope.order_by_departure_time(direction)
      when "arrival_time"
        scope.order_by_arrival_time(direction)
      when "starting_stop", "ending_stop"
        sa = params[:sort] == "starting_stop" ? @starting_stop : @ending_stop
        if sa.present?
          stop_point_ids = sa.stop_points.pluck(:id)
          if stop_point_ids.present?
            scope = scope.joins("INNER JOIN vehicle_journey_at_stops order_vjas ON order_vjas.vehicle_journey_id = vehicle_journeys.id")
            scope = scope.where('order_vjas.stop_point_id' => stop_point_ids)
            scope = scope.order("(('2000/01/01 ' || order_vjas.departure_time)::timestamp + (order_vjas.departure_day_offset::text || ' days')::interval) #{direction}")
          end
        end
        scope
      else
        scope.order "#{params[:sort]} #{direction}"
    end
  end
end
