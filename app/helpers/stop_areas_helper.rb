# coding: utf-8
module StopAreasHelper

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
        content_tag(:span, nil, class: 'fa fa-pencil-alt fa-lg') +
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

  def stop_area_connections(connection_links, stop_area, workbench)
    table_builder_2 connection_links,
      [ \
        TableBuilderHelper::Column.new( \
          name: t('.connections.stop'), \
          attribute: Proc.new { |c| link_to c.associated_stop(stop_area.id).name, workbench_stop_area_referential_connection_link_path(workbench, c) } \
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
      cls: 'table',
      action: :index
  end

  def more_connections_link(stop_area, workbench)
    link_name = t('.connections.more', count: (stop_area.connection_links.count - 4))
    link_path = workbench_stop_area_referential_connection_links_path(workbench, :'q[departure_name_or_arrival_name_cont]' => stop_area.name)
    link_to link_name, link_path, class: 'btn btn-link'
  end

  def stop_and_connections_json(stop_area, add_connections)
    a = [stop_area.slice(:id, :longitude, :latitude)]
    a += (stop_area.connection_links.map{|c| connected_stop_json_for_show(c, stop_area.id)}) if add_connections
    a.to_json
  end

  def connected_stop_json_for_show(connection_link, stop_id)
    stop = (connection_link.departure_id == stop_id ? connection_link.arrival : connection_link.departure)
    stop.slice(:id, :longitude, :latitude)
  end
end
