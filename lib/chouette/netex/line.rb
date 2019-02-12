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
      'TransportSubmode' => :transport_submode
    }
  end

  def presentation_attributes
    {
      'Colour' => :color,
      'TextColour' => :text_color
    }
  end

  def build_xml
    @builder.Line(resource_metas) do
      attributes_mapping
      ref 'OperatorRef', resource.company_light&.objectid
      ref 'RepresentedByGroupRef', resource.network&.objectid
      @builder.Presentation do
        attributes_mapping presentation_attributes
      end
    end
  end
end
