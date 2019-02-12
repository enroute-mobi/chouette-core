class Chouette::Netex::GroupOfLines < Chouette::Netex::Resource
  def attributes
    {
      'Name' => :name,
      'Description' => :comment,
      'PrivateCode' => :registration_number
    }
  end

  def to_xml(builder)
    builder.GroupOfLines(resource_metas) do
      attributes_mapping builder
    end
  end
end
