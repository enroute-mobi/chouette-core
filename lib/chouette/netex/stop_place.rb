class Chouette::Netex::StopPlace < Chouette::Netex::Resource
  def self.zdep_parents
    get_cache :zdep_parents
  end

  def build_cache
    parent_ids = collection.where(area_type: :zdep).where.not(parent_id: nil).distinct.pluck(:parent_id)
    self.class.set_cache :zdep_parents, parent_ids
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
      'Name' => :name,
      'Description' => :comment,
      'Url' => :url,
      'PrivateCode' => :registration_number
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

  def postal_address
    attributes_mapping(postal_address_attributes)
    ref 'CountryRef', resource.country_code&.upcase
  end

  def postal_address_id
    resource.objectid&.split(':')&.send(:[], (0..-2)).push('postal-code')&.join(':')
  end

  def key_list
    key_value('WaitingTime', :waiting_time)
    key_value('TimeZone', :time_zone)
    key_value('TimeZoneOffset', ->{ resource.time_zone_offset / 3600 })
  end

  def centroid(target=nil)
    target ||= resource
    node_if_content 'Centroid' do
      node_if_content 'Location' do
        @builder.Longitude(target.longitude) if target.longitude
        @builder.Latitude(target.latitude) if target.latitude
      end
    end
  end

  def alternative_names(target=nil)
    target ||= resource

    return unless target.localized_names.values.any?(&:present?)

    node_if_content 'alternativeNames' do
      target.localized_names.each do |k, v|
        if v.present?
          @builder.AlternativeName do
            @builder.NameType 'translation'
            @builder.Name(v, lang: k)
          end
        end
      end
    end
  end

  def quays
    return unless zdep_parents.include?(resource.id)

    @builder.quays do
      resource.children.where(area_type: :zdep).each do |child|
        @builder.Quay(version: :any, id: child.objectid) do
          node_if_content 'keyList' do
            custom_fields_as_key_values(child)
          end
          attributes_mapping({ 'Name' => :name, 'Description' => :comment }, child)
          centroid(child)
        end
      end
    end
  end

  def build_xml
    @builder.StopPlace(resource_metas) do
      attributes_mapping

      unless resource.commercial?
        @builder.PublicUse(public_use) if public_use
        if resource.area_type == 'border'
          @builder.BorderCrossing true
        end
      end

      @builder.StopPlaceType :other
      ref 'ParentSiteRef', resource.parent&.objectid

      @builder.PostalAddress(version: :any, id: postal_address_id) do
        postal_address
      end

      node_if_content 'keyList' do
        key_list
      end

      @builder.placeTypes do
        ref 'TypeOfPlaceRef', type_of_place
      end

      quays
      centroid
      alternative_names
    end
  end
end
