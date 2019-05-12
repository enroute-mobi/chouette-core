module StopAreasHelper
  def explicit_name(stop_area)
    name = localization = ""

    name += truncate(stop_area.name, :length => 30) || ""
    name += (" <small>["+ ( truncate(stop_area.registration_number, :length => 10) || "") + "]</small>") if stop_area.registration_number

    localization += stop_area.zip_code || ""
    localization += ( truncate(stop_area.city_name, :length => 15) ) if stop_area.city_name

    ( "<img src='#{stop_area_picture_url(stop_area)}'/>" + " <span style='height:25px; line-height:25px; margin-left: 5px; '>" + name + " <small style='height:25px; line-height:25px; margin-left: 10px; color: #555;'>" + localization + "</small></span>").html_safe
  end

  def label_for_country country, txt=nil
    if country.to_s =~ /_/ # en_GB => gb
      country = StopAreaReferential.translate_code_to_official country
      country = country.to_s.split('_').last.downcase
    end
    "#{txt} <span title='#{ISO3166::Country[country]&.translation(I18n.locale)}' class='flag-icon flag-icon-#{country.downcase} mr-xs'></span>".html_safe
  end

  def genealogical_title
    return t("stop_areas.genealogical.genealogical_routing") if @stop_area.stop_area_type == 'itl'
    t("stop_areas.genealogical.genealogical")
  end

  def show_map?
    manage_itl || @stop_area.long_lat_type != nil
  end

  def manage_access_points
    @stop_area.stop_area_type == 'stop_place' || @stop_area.stop_area_type == 'commercial_stop_point'
  end
  def manage_itl
    @stop_area.stop_area_type == 'itl'
  end
  def manage_parent
    @stop_area.stop_area_type != 'itl'
  end
  def manage_children
    @stop_area.stop_area_type == 'stop_place' || @stop_area.stop_area_type == 'commercial_stop_point'
  end

  def pair_key(access_link)
    "#{access_link.access_point.id}-#{access_link.stop_area.id}"
  end

  def geo_data(sa, sar)
    if sa.long_lat_type.nil?
      content_tag :span, '-'
    else
      if !sa.projection.nil?
        content_tag :span, "#{sa.projection_x}, #{sa.projection_y}"

      elsif !sa.long_lat_type.nil?
        content_tag :span, "#{sa.long_lat_type} : #{sa.latitude}, #{sa.longitude}"
      end
    end
  end

  def stop_area_registration_number_title stop_area
    if stop_area&.stop_area_referential&.registration_number_format.present?
      return t("formtastic.titles.stop_area.registration_number_format", registration_number_format: stop_area.stop_area_referential.registration_number_format)
    end
    t "formtastic.titles#{format_restriction_for_locales(@referential)}.stop_area.registration_number"
  end

  def stop_area_registration_number_is_required stop_area
    val = format_restriction_for_locales(@referential) == '.hub'
    val ||= stop_area&.stop_area_referential&.registration_number_format.present?
    val
  end

  def stop_area_registration_number_value stop_area
    stop_area&.registration_number
  end

  def stop_area_registration_number_hint
    t "formtastic.hints.stop_area.registration_number"
  end

  def stop_area_status(status)
    case status
      when :confirmed
        content_tag(:span, nil, class: 'fa fa-check-circle fa-lg text-success') +
        t('activerecord.attributes.stop_area.confirmed')
      when :deactivated
        content_tag(:span, nil, class: 'fa fa-exclamation-circle fa-lg text-danger') +
        t('activerecord.attributes.stop_area.deactivated')
      else
        content_tag(:span, nil, class: 'fa fa-pencil fa-lg text-info') +
        t('activerecord.attributes.stop_area.in_creation')
    end
  end

  def stop_area_status_options
    Chouette::StopArea.statuses.map do |status|
      [ t(status, scope: 'activerecord.attributes.stop_area'), status ]
    end
  end

  def area_type_options(kind = nil)
    kind ||= current_user.organisation.has_feature?("route_stop_areas_all_types") ? :all : :commercial

    return [] if kind == :all && !current_user.organisation.has_feature?("route_stop_areas_all_types")

    Chouette::AreaType.options(kind)
  end

  def referent_options
    [[t(true), true], [t(false), false]]
  end

  def stop_area_identification_metadatas(stop_area, stop_area_referential)
    attributes = { t('id_reflex') => stop_area.get_objectid.short_id,
      Chouette::StopArea.tmf('name') => stop_area.name,
      Chouette::StopArea.tmf('kind') => stop_area.kind,
    }

    if has_feature?(:stop_area_localized_names)
      stop_area.stop_area_referential.sorted_locales.each do |locale|
        val = stop_area.localized_names[locale[:code]]
        attributes.merge!(label_for_country(locale[:code], Chouette::StopArea.tmf('name')) => val ) if val.present?
      end
    end

    attributes.merge!(Chouette::StopArea.tmf('parent') => stop_area.parent ? link_to(stop_area.parent.name, stop_area_referential_stop_area_path(stop_area_referential, stop_area.parent)) : "-") if stop_area.commercial?
    attributes.merge!(Chouette::StopArea.tmf('referent_id') => stop_area.referent ? link_to(stop_area.referent.name, stop_area_referential_stop_area_path(stop_area_referential, stop_area.referent)) : "-") if !stop_area.is_referent
    attributes.merge!(Chouette::StopArea.tmf('stop_area_type') => Chouette::AreaType.find(stop_area.area_type).try(:label),
      Chouette::StopArea.tmf('registration_number') => stop_area.registration_number,
      Chouette::StopArea.tmf('status') => stop_area_status(stop_area.status),
    )
    providers = stop_area.stop_area_providers.map do |provider|
      link_to provider.name, [provider.stop_area_referential, provider]
    end

    attributes.merge!(StopAreaProvider.t.capitalize => providers.to_sentence.html_safe)
  end

  def stop_area_location_metadatas(stop_area, stop_area_referential)
    {
      "Coordonnées" => geo_data(stop_area, stop_area_referential),
      Chouette::StopArea.tmf('street_name') => stop_area.street_name,
      Chouette::StopArea.tmf('zip_code') => stop_area.zip_code,
      Chouette::StopArea.tmf('city_name') => stop_area.city_name,
      Chouette::StopArea.tmf('postal_region') => stop_area.postal_region,
      Chouette::StopArea.tmf('country_code') => stop_area.country_code.presence || '-',
      Chouette::StopArea.tmf('time_zone') => stop_area.time_zone.presence || '-',
    }
  end

  def stop_area_general_metadatas(stop_area)
    attributes = {}
    attributes.merge!(Chouette::StopArea.tmf('waiting_time') => stop_area.waiting_time_text) if has_feature?(:stop_area_waiting_time)
    attributes.merge!(Chouette::StopArea.tmf('fare_code') => stop_area.fare_code,
      Chouette::StopArea.tmf('url') => stop_area.url,
    )
    unless manage_itl
      attributes.merge!(Chouette::StopArea.tmf('mobility_restricted_suitability') => stop_area.mobility_restricted_suitability? ? "yes".t : "no".t,
        Chouette::StopArea.tmf('stairs_availability') => stop_area.stairs_availability? ? "yes".t : "no".t,
        Chouette::StopArea.tmf('lift_availability') => stop_area.lift_availability? ? "yes".t : "no".t,
      )
    end
    stop_area.custom_fields.each do |code, field|
      attributes.merge!(field.name => field.display_value)
    end
    attributes.merge!(Chouette::StopArea.tmf('comment') => stop_area.try(:comment))
  end

  def associated_stop_link(stop_area, stop_area_referential)
    link_to(stop_area.name, stop_area_referential_stop_area_path(stop_area_referential, stop_area))
  end

  def stop_area_connections(connection_links, stop_area, stop_area_referential)
    table_builder_2 connection_links,
      [ \
        TableBuilderHelper::Column.new( \
          name: t('.connections.stop'), \
          attribute: Proc.new { |c| associated_stop_link(c.associated_stop(stop_area.id), stop_area_referential) } \
        ), \
        TableBuilderHelper::Column.new( \
          name: t('.connections.duration'), \
          attribute: Proc.new { |c| c.default_duration / 60 } \
        ), \
        TableBuilderHelper::Column.new( \
          name: t('.connections.direction'), \
          attribute: Proc.new { |c| t(".connections.#{c.direction stop_area.id}") } \
        ), \
      ].compact,
      sortable: false,
      links: [:show],
      cls: 'table'
  end

  def more_connections_link(stop_area, stop_area_referential)
    link_name = t('.connections.more', count: (stop_area.connection_links.count - 4))
    link_path = stop_area_referential_connection_links_path(stop_area_referential, :'q[departure_name_or_arrival_name_cont]' => stop_area.name)
    link_to link_name, link_path, class: 'btn btn-link'
  end

  def stop_and_connections_json(stop_area)
    ([stop_area.slice(:id, :longitude, :latitude)] + (stop_area.connection_links.map{|c| connected_stop_json_for_show(c, stop_area.id)})).to_json
  end

  def connected_stop_json_for_show(connection_link, stop_id)
    stop = (connection_link.departure_id == stop_id ? connection_link.arrival : connection_link.departure)
    stop.slice(:id, :longitude, :latitude)
  end
  
  def stop_area_specific_stops(specific_stops, stop_area_referential)
    table_builder_2 specific_stops,
      [ \
        TableBuilderHelper::Column.new( \
          key: :name, \
          attribute: Proc.new { |s| link_to s.name, stop_area_referential_stop_area_path(stop_area_referential, s) } \
        ), \
        TableBuilderHelper::Column.new( \
          name: t('id_reflex'), \
          attribute: Proc.new { |s| s.get_objectid.try(:short_id) }, \
        ), \
      ].compact,
      sortable: false,
      cls: 'table'
  end
end
