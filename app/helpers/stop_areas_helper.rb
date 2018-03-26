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
    "#{txt} <span title='#{ISO3166::Country[country]&.translation(I18n.locale)}' class='flag-icon flag-icon-#{country}'></span>".html_safe
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
        content_tag :span, "#{sa.long_lat_type} : #{sa.longitude}, #{sa.latitude}"
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
end
