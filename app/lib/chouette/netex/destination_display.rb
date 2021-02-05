class Chouette::Netex::DestinationDisplay < Chouette::Netex::Resource
  def attributes
    {
      'FrontText' => :published_name
    }
  end

  def build_xml
    @builder.DestinationDisplay(resource_metas) do
      attribute 'FrontText'
    end
  end
end
