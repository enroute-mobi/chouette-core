class Chouette::Netex::StopPlace < Chouette::Netex::Resource
  def self.zdep_parents
    @zdep_parents
  end

  def build_cache
    parent_ids = collection.where(area_type: :zdep).where.not(parent_id: nil).distinct.pluck(:parent_id)
    self.class.instance_variable_set '@zdep_parents', parent_ids
  end

  def zdep_parents
    self.class.zdep_parents || build_cache && self.class.zdep_parents
  end

  def resource_metas
    default_resource_metas.update(
      status: resource.deactivated? ? 'inactive' : 'active'
    )
  end

  def type_of_place
    case resource.area_type
    when 'gdl'
      'groupOfStopPlaces'
    when 'lda'
      'generalStopPlace'
    when 'zdlp'
      'monomodalStopPlace'
    when 'zdep'
      'quay'
    else
      resource.area_type
    end
  end

  def attributes
    {
      'Name' => 'name',
      'Description' => 'comment',
      'Url' => 'url',
      'PrivateCode' => 'registration_number'
    }
  end

  def postal_address_attributes
    {
      'Town' => :city_name,
      'AddressLine1' => :street_name,
      'PostCode' => :zip_code
    }
  end

  def public_use
    resource.area_type == 'border' ? 'staffOnly' : nil
  end

  def postal_address(builder)
    attributes_mapping(builder, postal_address_attributes)
    builder.CountryRef resource.country_code&.upcase
  end

  def postal_address_id
    resource.objectid&.split(':')&.send(:[], (0..-2)).push('postal-code')&.join(':')
  end

  def key_list(builder)
    key_value('WaitingTime', :waiting_time, builder)
    key_value('TimeZone', :time_zone, builder)
    key_value('TimeZoneOffset', ->{ resource.time_zone_offset / 3600 }, builder)
  end

  def centroid(builder, target=nil)
    target ||= resource
    builder.Centroid do
      builder.Location do
        builder.Longitude target.longitude
        builder.Latitude target.latitude
      end
    end
  end

  def alternative_names(builder, target=nil)
    target ||= resource

    return unless target.localized_names.values.any?(&:present?)

    builder.alternativeNames do
      target.localized_names.each do |k, v|
        if v.present?
          builder.AlternativeName do
            builder.NameType 'translation'
            builder.Name(v, lang: k)
          end
        end
      end
    end
  end

  def quays(builder)
    return unless zdep_parents.include?(resource.id)

    builder.quays do
      resource.children.where(area_type: :zdep).each do |child|
        builder.Quay(version: :any, id: child.objectid) do
          builder.keyList do
            custom_fields_as_key_values(builder, child)
            builder.Name child.name
            builder.Description child.comment
            centroid(builder, child)
          end
        end
      end
    end
  end

  def to_xml(builder)
    builder.StopPlace(resource_metas) do
      attributes_mapping builder

      unless resource.commercial?
        builder.PublicUse public_use
        if resource.area_type == 'border'
          builder.BorderCrossing true
        end
      end

      builder.StopPlaceType :other
      builder.ParentSiteRef resource.parent&.objectid

      builder.PostalAddress(version: :any, id: postal_address_id) do
        postal_address(builder)
      end

      builder.keyList do
        key_list(builder)
      end

      builder.placeTypes do
        builder.TypeOfPlaceRef(ref: type_of_place)
      end

      quays(builder)
      centroid(builder)
      alternative_names(builder)
    end
  end
end
