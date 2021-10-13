module ConnectionLinksHelper
  def connection_link_duration_select f, duration
    content_tag(:div, class: 'col-md-6') do
      selected = f.object.send(duration).presence
      collection = selected ? (0..selected+10) : (0..15)
      collection = collection.map { |x| [x,x*60]  }.to_h

      f.input duration, as: :integer, min: 0, wrapper: :horizontal_shrinked_input, input_html: { value: selected }
    end
  end

  def localized_both_ways(connection_link)
    t("connection_links.direction.#{connection_link.both_ways ? 'both' : 'one'}")
  end

  def connection_link_type_options
    Chouette::ConnectionLink.connection_link_types.map do |link_type|
      [ t(link_type, scope: 'activerecord.attributes.connection_link'), link_type ]
    end
  end

  def connection_link_id_with_icon_color(color, text)
    image_pack_tag(asset_path("icons/map_pin_#{color}.png"), class: 'fa fa-square fa-lg') + text
  end

  def connection_link_durations_display(duration)
    return '-' if duration.nil? || duration == 0
    duration/60
  end

  def connection_link_identification_metadatas(connection_link)
    {
      t('id_reflex') => connection_link.get_objectid.short_id,
      t('connection_links.direction.name') => localized_both_ways(connection_link),
    }
  end

  def connection_link_path_metadatas(connection_link)
    {
      Chouette::ConnectionLink.tmf('default_duration') => (connection_link_durations_display connection_link.default_duration),
      Chouette::ConnectionLink.tmf('frequent_traveller_duration') => (connection_link_durations_display connection_link.frequent_traveller_duration),
      Chouette::ConnectionLink.tmf('occasional_traveller_duration') => (connection_link_durations_display connection_link.occasional_traveller_duration),
      Chouette::ConnectionLink.tmf('mobility_restricted_traveller_duration') => (connection_link_durations_display connection_link.mobility_restricted_traveller_duration),
      Chouette::ConnectionLink.tmf('link_distance') => connection_link.link_distance,
    }
  end

  def connection_link_departure_metadatas(connection_link, workbench)
    attributes = {
      t('id_reflex') => connection_link_id_with_icon_color('orange', connection_link.departure.get_objectid.short_id),
      Chouette::StopArea.tmf('name') => link_to(connection_link.departure.name, workbench_stop_area_referential_stop_area_path(workbench, connection_link.departure)),
    }

    attributes.merge!(Chouette::StopArea.tmf('parent') => connection_link.departure.parent ? link_to(connection_link.departure.parent.name, workbench_stop_area_referential_stop_area_path(workbench, connection_link.departure.parent)) : "-") if connection_link.departure.commercial?
    attributes.merge!(Chouette::StopArea.tmf('stop_area_type') => Chouette::AreaType.find(connection_link.departure.area_type).try(:label))
  end

  def connection_link_arrival_metadatas(connection_link, workbench)
    attributes = {
      t('id_reflex') => connection_link_id_with_icon_color('blue', connection_link.arrival.get_objectid.short_id),
      Chouette::StopArea.tmf('name') => link_to(connection_link.arrival.name, workbench_stop_area_referential_stop_area_path(workbench, connection_link.arrival)),
    }

    attributes.merge!(Chouette::StopArea.tmf('parent') => connection_link.arrival.parent ? link_to(connection_link.arrival.parent.name, workbench_stop_area_referential_stop_area_path(workbench, connection_link.arrival.parent)) : "-") if connection_link.arrival.commercial?
    attributes.merge!(Chouette::StopArea.tmf('stop_area_type') => Chouette::AreaType.find(connection_link.arrival.area_type).try(:label))
  end

  def connection_link_general_metadatas(connection_link)
    {
      Chouette::ConnectionLink.tmf('connection_link_type') => t(connection_link.link_type, scope: 'activerecord.attributes.connection_link'),
      Chouette::ConnectionLink.tmf('name') => connection_link.try(:name),
      Chouette::ConnectionLink.tmf('comment') => connection_link.try(:comment)
    }
  end

  def connection_link_json_for_show(connection_link, serialize: true)
    data = connection_link.slice(:id)
    both_areas = connection_link.slice(:departure, :arrival).map do |key, value|
      {key => value.attributes.slice("longitude", "latitude")}
    end
    data = data.merge!(both_areas.reduce(:merge))
    data = data.to_json if serialize
    data
  end
end
