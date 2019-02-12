class Chouette::Netex::Operator < Chouette::Netex::Resource
  def attributes
    {
      'PublicCode'  => :code,
      'CompanyCode' => :registration_number,
      'Name'        => :name,
      'ShortName'   => :short_name
    }
  end

  def contact_attributes
    {
      'Email' => :email,
      'Phone' => :phone,
      'Url'   => :url
    }
  end

  def build_xml
    @builder.Operator(resource_metas) do
      node_if_content 'keyList' do
        custom_fields_as_key_values
      end

      attributes_mapping

      node_with_attributes_mapping 'ContactDetails', contact_attributes
    end
  end
end
