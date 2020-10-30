class Chouette::Netex::RoutingConstraintZone < Chouette::Netex::Resource
  def self.stop_points
    get_cache :stop_points
  end

  def build_cache
    # We cannot "include" stop_points, as it is not an AR relation

    sql = "select array_agg(c) AS ids
    from (
      select DISTINCT(unnest(stop_point_ids))
      from \"#{@document.referential.slug}\".routing_constraint_zones
    ) as dt(c);"
    res = resource.class.connection.execute(sql).first
    ids = res['ids'][1..-2].split(',')
    stop_points = Chouette::StopPoint.where(id: ids).select(:id, :objectid).reduce(Hash.new) do |h, s|
      h[s.id] = s
      h
    end
    self.class.set_cache :stop_points, stop_points
  end

  def stop_points_cache
    self.class.stop_points || build_cache && self.class.stop_points
  end

  def stop_points
    stop_points_cache.values_at *resource.stop_point_ids
  end

  def resource_is_valid?
    resource.errors.add(:route, :missing) unless resource.route.present?
    resource.errors.add(:stop_point_ids, I18n.t('activerecord.errors.models.routing_constraint_zone.attributes.stop_points.not_enough_stop_points')) if stop_points.length < 2
    resource.errors.empty?
  end

  def attributes
    {
      'Name' => :name,
      'ZoneUse' => 'cannotBoardAndAlightInSameZone'
    }
  end

  def members
    @builder.members do
      stop_points.each do |stop_point|
        ref 'ScheduledStopPointRef', id_with_entity('ScheduledStopPoint', stop_point)
      end
    end
  end

  def build_xml
    @builder.RoutingConstraintZone(resource_metas) do
      node_if_content :keyList do
        key_value 'routeRef', resource.route.objectid
      end
      attribute 'Name'
      members
      attribute 'ZoneUse'
      node_if_content :lines do
        ref 'LineRef', resource.route.line.objectid
      end
    end
  end
end
