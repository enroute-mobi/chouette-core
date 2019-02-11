class Chouette::Netex::Document
  def initialize(referential, date_range)
    @referential = referential
    @date_range = date_range
  end

  def build
    @builder = Nokogiri::XML::Builder.new(encoding: 'utf-8') do |xml|
      xml.PublicationDelivery(
        'xmlns' => 'http://www.netex.org.uk/netex',
        'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
        'xmlns:gml' => 'http://www.opengis.net/gml/3.2',
        'xmlns:siri' => 'http://www.siri.org.uk/siri',
        'version' => '1.04:NO-NeTEx-networktimetable:1.0'
      ) {
        xml.PublicationTimestamp Time.now.utc.strftime('%Y-%m-%dT%H:%M:%S.%1NZ')
        xml.ParticipantRef participant_ref
        xml.dataObjects {
          xml.CompositeFrame(version: :any, id: 'Chouette:CompositeFrame:1') {
            xml.frames {
              self.frames(xml)
            }
          }
        }
      }
    end
  end

  def to_xml
    @builder.to_xml
  end

  def temp_file
    temp_file = Tempfile.new ['netex_full', '.xml']
    temp_file.write self.to_xml
    temp_file.rewind
    temp_file
  end

  def participant_ref
    "enRoute"
  end

  def frames(builder)
    
  end
end
