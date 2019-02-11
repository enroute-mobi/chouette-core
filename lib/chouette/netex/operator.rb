class Chouette::Netex::Operator < Chouette::Netex::Resource
  def attributes
    {
      'PublicCode'  => 'code',
      'CompanyCode' => 'registration_number',
      'Name'        => 'name',
      'ShortName'   => 'short_name'
    }
  end

  def contact_attributes
    {
      'Email' => 'email',
      'Phone' => 'phone',
      'Url'   => 'url'
    }
  end

  def to_xml(builder)
    builder.Operator(resource_metas) do
      builder.keyList do
        custom_fields_as_key_values(builder)
      end

      attributes_mapping builder

      builder.ContactDetails do
        attributes_mapping(builder, contact_attributes)
      end
    end
  end
end
