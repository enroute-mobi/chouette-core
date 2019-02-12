class Chouette::Netex::GroupOfLines < Chouette::Netex::Resource
  def attributes
    {
      'Name' => :name,
      'Description' => :comment,
      'PrivateCode' => :registration_number
    }
  end

  def build_xml
    @builder.GroupOfLines(resource_metas) do
      attributes_mapping
    end
  end
end
