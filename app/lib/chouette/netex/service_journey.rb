class Chouette::Netex::ServiceJourney < Chouette::Netex::Resource
  def resource_is_valid?
    unless resource.vehicle_journey_at_stops.all? { |vjas|
      vjas.departure_time.present? || vjas.arrival_time.present?
    }
      resource.errors.add(:vehicle_journey_at_stops, :invalid_times)
      return false
    end
    true
  end

  def attributes
    {
      'Name' => :published_journey_name,
      'TransportMode' => :transport_mode
    }
  end

  def day_types
    node_if_content 'dayTypes' do
      resource.time_tables.each do |tt|
        ref 'DayTypeRef', tt.objectid
      end
    end
  end

  def purchase_windows
    resource.purchase_windows.map do |pw|
      bounding_dates = pw.bounding_dates
       "#{bounding_dates.first}..#{bounding_dates.last}"
    end.join(',')
  end

  def passingTimes
    node_if_content 'passingTimes' do
      last = resource.vehicle_journey_at_stops.last
      resource.vehicle_journey_at_stops.each_with_index do |vjas, i|
        @builder.TimetabledPassingTime do
          ref 'StopPointInJourneyPatternRef', id_with_entity('StopPointInJourneyPattern', resource.journey_pattern_only_objectid, vjas.stop_point)
          if i > 0
            arrival_time_of_day = vjas.arrival_local_time_of_day
            @builder.ArrivalTime arrival_time_of_day.to_iso_8601
            @builder.ArrivalDayOffset(arrival_time_of_day.day_offset) if arrival_time_of_day.day_offset?
          end
          if vjas != last
            departure_time_of_day = vjas.arrival_local_time_of_day
            if arrival_time_of_day != departure_time_of_day
              @builder.DepartureTime departure_time_of_day.to_iso_8601
              @builder.DepartureDayOffset(departure_time_of_day.day_offset) if departure_time_of_day.day_offset?
            end
          end
        end
      end
    end
  end

  def notices
    node_if_content 'noticeAssignments'  do
      resource.line_notices.each_with_index do |line_notice, i|
        @builder.NoticeAssignment(id: id_with_entity('NoticeAssignment', line_notice), version: :any, order: i) do
          ref 'NoticeRef', line_notice.objectid
        end
      end
    end
  end

  def build_xml
    @builder.ServiceJourney(resource_metas) do
      node_if_content 'keyList' do
        custom_fields_as_key_values
        key_value 'PurchaseWindows', purchase_windows
      end

      attributes_mapping
      notices
      day_types

      ref 'JourneyPatternRef', resource.journey_pattern_only_objectid.objectid
      ref 'OperatorRef', resource.company_light&.objectid

      passingTimes
    end
  end
end
