module VehicleJourneysHelper

  def vehicle_name( vehicle)
    if !vehicle.published_journey_name.blank?
      vehicle.published_journey_name.first(8)
    elsif !vehicle.published_journey_identifier.blank?
      vehicle.published_journey_identifier.first(8)
    elsif !vehicle.number.blank?
      vehicle.number
    else
      vehicle.id
    end
  end

  def missing_time_check( is_present)
    return "missing" if (is_present && is_present.departure_time.nil?)
  end

  def vehicle_departure(vehicle, departure_time=nil)
    unless departure_time
      first_vjas = vehicle.vehicle_journey_at_stops.first
      return '' unless first_vjas.departure_time
      departure_time = first_vjas.departure_time
    end
    l(departure_time, :format => :hour).gsub( /  /, ' ')
  end

  def vehicle_title(vehicle, journey_frequency=nil)
    return t("vehicle_journeys.vehicle_journey#{'_frequency' if vehicle.frequency?}.title_stopless", :name => vehicle_name( vehicle)) if vehicle.vehicle_journey_at_stops.empty?
    first_vjas = vehicle.vehicle_journey_at_stops.first
    if vehicle.frequency? && journey_frequency
      t("vehicle_journeys.vehicle_journey_frequency.title_frequency",
        :interval => l(journey_frequency.scheduled_headway_interval, format: :hour),
        :stop => first_vjas.stop_point.stop_area.name,
        :time_first => vehicle_departure(nil, journey_frequency.first_departure_time),
        :time_last => vehicle_departure(nil, journey_frequency.last_departure_time))
    else
      t("vehicle_journeys.vehicle_journey#{'_frequency' if vehicle.frequency?}.title",
            :stop => first_vjas.stop_point.stop_area.name,
            :time => vehicle_departure(vehicle, (journey_frequency ? journey_frequency.first_departure_time : nil )))
    end
  end

  def route_journey_pattern_label_pairs route
    route
      .journey_patterns
      .zip_map { |jp| journey_name(jp) }
  end

  def edit_vehicle_title( vehicle)
    return t('vehicle_journeys.edit.title_stopless', :name => vehicle_name( vehicle)) if vehicle.vehicle_journey_at_stops.empty?
    first_vjas = vehicle.vehicle_journey_at_stops.first
    t('vehicle_journeys.edit.title',
          :name => vehicle_name( vehicle),
          :stop => first_vjas.stop_point.stop_area.name,
          :time => vehicle_departure(vehicle))
  end

  def exist_vehicle_journeys?(route)
    route.vehicle_journeys.count > 0
  end

  def table_builder_column_for_stop_area stop_area
    return nil unless stop_area
    TableBuilderHelper::Column.new(
      name: stop_area.name,
      attribute: Proc.new {|v| v.vehicle_journey_at_stops.find{|vjas| vjas.stop_point.stop_area_id == stop_area.id}&.departure },
      sortable: false
    )
  end

  def vehicle_journey_stop_headline prev_sp, sp
    if has_feature?(:long_distance_routes)
      headline = prev_sp && prev_sp.stop_area.country_code
      headline = sp.stop_area.country_code != headline
      headline && sp.stop_area.country_name
    else
      headline = prev_sp && prev_sp.stop_area.city_name
      headline = sp.stop_area.city_name != headline
      headline && sp.stop_area.city_name
    end
  end

  def display_time_of_day(time_of_day)
    return '-' unless time_of_day

    if time_of_day.day_offset?
      I18n.t('vehicle_journeys.index.vjas.time_of_day', time: time_of_day.to_hms, offset: time_of_day.day_offset)
    else
      time_of_day.to_hms
    end
  end

end
