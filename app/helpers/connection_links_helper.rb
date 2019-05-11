module ConnectionLinksHelper
  def localized_both_ways(connection_link)
    t("connection_links.ways.#{connection_link.both_ways ? 'both' : 'one'}")
  end

  def connection_link_identification_metadatas(connection_link)
    {
      t('id_reflex') => connection_link.get_objectid.short_id,
      Chouette::ConnectionLink.tmf('both_ways') => localized_both_ways(connection_link),
    }
  end

  def connection_link_path_metadatas(connection_link)
    {
      Chouette::ConnectionLink.tmf('default_duration') => (connection_link.default_duration || 0) / 60,
      Chouette::ConnectionLink.tmf('frequent_traveller_duration') => (connection_link.frequent_traveller_duration || 0) / 60,
      Chouette::ConnectionLink.tmf('occasional_traveller_duration') => (connection_link.occasional_traveller_duration || 0) / 60,
      Chouette::ConnectionLink.tmf('mobility_restricted_traveller_duration') => (connection_link.mobility_restricted_traveller_duration || 0) / 60,
      Chouette::ConnectionLink.tmf('link_distance') => connection_link.link_distance,
    }
  end

  def connection_link_departure_metadatas(connection_link, stop_area_referential)
    attributes = {
      t('id_reflex') => connection_link.departure.get_objectid.short_id,
      Chouette::StopArea.tmf('name') => connection_link.departure.name,
    }

    attributes.merge!(Chouette::StopArea.tmf('parent') => connection_link.departure.parent ? link_to(connection_link.departure.parent.name, stop_area_referential_stop_area_path(stop_area_referential, connection_link.departure.parent)) : "-") if connection_link.departure.commercial?
    attributes.merge!(Chouette::StopArea.tmf('kind') => connection_link.departure.kind)
  end

  def connection_link_arrival_metadatas(connection_link, stop_area_referential)
    attributes = {
      t('id_reflex') => connection_link.arrival.get_objectid.short_id,
      Chouette::StopArea.tmf('name') => connection_link.arrival.name,
    }

    attributes.merge!(Chouette::StopArea.tmf('parent') => connection_link.arrival.parent ? link_to(connection_link.arrival.parent.name, stop_area_referential_stop_area_path(stop_area_referential, connection_link.arrival.parent)) : "-") if connection_link.arrival.commercial?
    attributes.merge!(Chouette::StopArea.tmf('kind') => connection_link.arrival.kind)
  end

  def connection_link_general_metadatas(connection_link)
    {
      Chouette::ConnectionLink.tmf('link_type') => connection_link.link_type,
      Chouette::ConnectionLink.tmf('name') => connection_link.try(:name),
      Chouette::ConnectionLink.tmf('comment') => connection_link.try(:comment)
    }
  end
end
