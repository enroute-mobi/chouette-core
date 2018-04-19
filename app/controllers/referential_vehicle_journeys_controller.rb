#
# Browse all VehicleJourneys of the Referential
#
class ReferentialVehicleJourneysController < ChouetteController
  include ReferentialSupport
  include RansackDateFilter

  before_action only: [:index] { set_date_time_params("purchase_window", Date, prefix: :purchase_window) }
  before_action only: [:index] { set_date_time_params("time_table", Date, prefix: :time_table) }

  defaults :resource_class => Chouette::VehicleJourney, collection_name: :vehicle_journeys

  requires_feature :referential_vehicle_journeys

  def index
    if params[:q] && params[:q][:route_line_id_eq].present?
      @filtered_line = Chouette::Line.find(params[:q][:route_line_id_eq])
    end

    index!
  end

  private

  def collection
    @q ||= end_of_association_chain
    @q = @q.with_stop_area_ids(params[:q][:stop_area_ids]) if params[:q] && params[:q][:stop_area_ids]
    @q = ransack_period_range(scope: @q, error_message:  t('vehicle_journeys.errors.purchase_window'), query: :in_purchase_window, prefix: :purchase_window)
    @q = ransack_period_range(scope: @q, error_message:  t('vehicle_journeys.errors.time_table'), query: :with_matching_timetable, prefix: :time_table)
    @starting_stop = params[:q] && params[:q][:stop_areas] && params[:q][:stop_areas][:start].present? ? Chouette::StopArea.find(params[:q][:stop_areas][:start]) : nil
    @ending_stop = params[:q] && params[:q][:stop_areas] && params[:q][:stop_areas][:end].present? ? Chouette::StopArea.find(params[:q][:stop_areas][:end]) : nil

    if @starting_stop
      @q =
        unless @ending_stop
          @q.with_stop_area_id(@starting_stop.id)
        else
          @q.with_ordered_stop_area_ids(@starting_stop.id, @ending_stop.id)
        end
    end

    @q = @q.ransack(params[:q])
    @vehicle_journeys ||= @q.result
    @vehicle_journeys = parse_order @vehicle_journeys
    @vehicle_journeys = @vehicle_journeys.paginate page: params[:page], per_page: params[:per_page] || 10
    @all_companies = Chouette::Company.where("id IN (#{@referential.vehicle_journeys.select(:company_id).to_sql})").distinct

  end

  def parse_order scope
    return scope.order(:published_journey_name) unless params[:sort].present?
    direction = params[:direction] || "asc"
    attributes = Chouette::VehicleJourney.column_names.map{|n| "vehicle_journeys.#{n}"}.join(',')
    case params[:sort]
      when "line"
        scope.order("lines.name #{direction}").joins(route: :line)
      when "route"
        scope.order("routes.name #{direction}").joins(:route)
      when "departure_time"
        scope.joins(:vehicle_journey_at_stops).group(attributes).select(attributes).order("MIN(vehicle_journey_at_stops.departure_time) #{direction}")
      when "arrival_time"
        scope.joins(:vehicle_journey_at_stops).group(attributes).select(attributes).order("MAX(vehicle_journey_at_stops.departure_time) #{direction}")
      else
        scope.order "#{params[:sort]} #{direction}"
      end
  end
end
