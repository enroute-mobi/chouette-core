class Chouette::Netex::Line < Chouette::Netex::Resource
  def resource_metas
    default_resource_metas.update(
      status: resource.active? ? 'active' : 'inactive'
    )
  end

  def attributes
    {
      'Name' => ->{ resource.published_name.presence || resource.name },
      'TransportMode' => :transport_mode
    }
  end

  def extra_attributes
    {
      'Url' => :url,
      'PublicCode' => :number,
      'PrivateCode' => :registration_number
    }
  end

  def presentation_attributes
    {
      'Colour' => :color,
      'TextColour' => :text_color
    }
  end

  def additional_operators
    return if resource.secondary_company_ids.nil? || resource.secondary_company_ids.empty?

    Chouette::Company.where(id: resource.secondary_company_ids).pluck(:objectid).each do |objectid|
      ref 'OperatorRef', objectid
    end
  end

  def build_xml
    @builder.Line(resource_metas) do
      attributes_mapping
      node_if_content 'TransportSubmode' do
        @builder.BusSubmode(resource.transport_submode) if resource.transport_submode
      end
      attributes_mapping extra_attributes
      ref 'OperatorRef', resource.company_light&.objectid
      node_if_content 'additionalOperators' do
        additional_operators
      end
      ref 'RepresentedByGroupRef', resource.network&.objectid
      node_if_content 'Presentation' do
        attributes_mapping presentation_attributes
      end
      node_if_content 'notices' do
        resource.line_notices.each do |line_notice|
          @builder.Notice(id: line_notice.objectid, version: :any) do
            @builder.Name line_notice.title
            @builder.Text line_notice.content
            ref 'TypeOfNoticeRef', 'LineNotice'
          end
        end
      end
    end
  end
end
