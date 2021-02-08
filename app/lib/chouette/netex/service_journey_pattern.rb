class Chouette::Netex::ServiceJourneyPattern < Chouette::Netex::Resource
  def attributes_to_validate
    [{stop_points: :stop_point_lights}]
  end

  def attributes
    { 'Name' => :name }
  end

  def destination_display_ref
    (resource.published_name || resource.registration_number) && id_with_entity('DestinationDisplayforJourneyPattern', resource)
  end

  def stop_point_in_journey_pattern_id(stop_point)
    id_with_entity 'StopPointInJourneyPattern', resource, stop_point
  end

  def service_link_in_journey_pattern_id(start, finish)
    id_with_entity 'ServiceLinkInJourneyPattern', resource, start, finish
  end

  def service_link_ref(start, finish)
    id_with_entity 'ServiceLink', resource, start, finish
  end

  def points_in_sequence
    resource.stop_point_lights.each_with_index do |stop_point, i|
      @builder.StopPointInJourneyPattern(version: :any, id: stop_point_in_journey_pattern_id(stop_point), order: i+1) do
        ref 'ScheduledStopPointRef', id_with_entity('ScheduledStopPoint', stop_point)
        @builder.ForAlighting('false') if stop_point.for_alighting == 'forbidden'
        @builder.ForBoarding('false') if stop_point.for_boarding == 'forbidden'
      end
    end
  end

  def links_in_sequence
    i = 0
    resource.stop_point_lights.each_cons(2) do |start, finish|
      costs = resource.costs_between start, finish
      if costs[:time] || costs[:distance]
        i += 1
        @builder.ServiceLinkInJourneyPattern(version: :any, id: service_link_in_journey_pattern_id(start, finish), order: i) do
          ref 'ServiceLinkRef', service_link_ref(start, finish)
        end
      end
    end
  end

  def build_xml
    @builder.ServiceJourneyPattern(resource_metas) do
      node_if_content 'keyList' do
        custom_fields_as_key_values
      end
      attribute 'Name'
      ref 'RouteRef', resource.route.objectid
      ref 'DestinationDisplayRef', destination_display_ref

      node_if_content 'pointsInSequence' do
        points_in_sequence
      end

      node_if_content 'linksInSequence' do
        links_in_sequence
      end
    end
  end
end
