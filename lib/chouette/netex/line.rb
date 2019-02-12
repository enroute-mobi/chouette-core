class Chouette::Netex::Line < Chouette::Netex::Resource
  def resource_metas
    default_resource_metas.update(
      status: resource.deactivated? ? 'inactive' : 'active'
    )
  end

  def attributes
    {
      'Name' => :published_name,
      'Url' => :url,
      'PublicCode' => :number,
      'PrivateCode' => :registration_number,
      'TransportMode' => :transport_mode,
      'TransportSubmode' => :transport_submode,
      'OperatorRef' => ->{ resource.company_light&.objectid },
      'RepresentedByGroupRef' => ->{ resource.network&.objectid }
    }
  end

  def presentation_attributes
    {
      'Colour' => :color,
      'TextColour' => :text_color
    }
  end

  def to_xml(builder)
    builder.Line(resource_metas) do
      attributes_mapping builder
      builder.Presentation do
        attributes_mapping builder, presentation_attributes
      end
    end
  end
end
