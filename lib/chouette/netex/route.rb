class Chouette::Netex::Route < Chouette::Netex::Resource
  def attributes
    {
      'Name'            => ->{ resource.published_name.presence || resource.name },
      'DirectionType'   => :wayback
    }
  end

  def points_in_sequence
    resource.stop_points.each_with_index do |stop_point, i|
      @builder.PointOnRoute(version: :any, id: id_with_entity(stop_point, 'PointOnRoute'), order: i+1) do
        ref 'RoutePointRef', id_with_entity(stop_point, 'RoutePoint')
      end
    end
  end

  def build_xml
    @builder.Route(resource_metas) do
      attributes_mapping
      ref 'LineRef', resource.line.objectid
      ref 'InverseRouteRef', resource.opposite_route&.objectid
      node_if_content 'pointsInSequence' do
        points_in_sequence
      end
    end
  end
end
