class Chouette::Netex::PassengerStopAssignment < Chouette::Netex::Resource
  def resource_metas
    {
      version: :any,
      id: id_with_entity(resource, 'PassengerStopAssignment'),
      order: 0
    }
  end

  def parent_ref
    resource.stop_area_light.area_type == 'zdep' ? 'QuayRef' : 'StopPlaceRef'
  end

  def build_xml
    @builder.PassengerStopAssignment(resource_metas) do
      ref 'ScheduledStopPointRef', id_with_entity(resource, 'ScheduledStopPoint')
      ref parent_ref, resource.stop_area_light.objectid
    end
  end
end
