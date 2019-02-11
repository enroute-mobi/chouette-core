class Chouette::Netex::Document
  include Chouette::Netex::Helpers

  attr_accessor :referential

  def initialize(referential)
    @referential = referential
  end

  def build
    @builder = Nokogiri::XML::Builder.new(encoding: 'utf-8') do |xml|
      xml.PublicationDelivery(
        'xmlns' => 'http://www.netex.org.uk/netex',
        'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
        'xmlns:gml' => 'http://www.opengis.net/gml/3.2',
        'xmlns:siri' => 'http://www.siri.org.uk/siri',
        'version' => '1.04:NO-NeTEx-networktimetable:1.0'
      ) do
        xml.PublicationTimestamp format_time(Time.now)
        xml.ParticipantRef participant_ref
        xml.dataObjects do
          xml.CompositeFrame(version: :any, id: 'Chouette:CompositeFrame:1') do
            xml.frames do
              self.frames(xml)
            end
          end
        end
      end
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

  protected

  def frames(builder)
    builder.ResourceFrame(version: :any, id: 'Chouette:ResourceFrame:1') do
      builder.organisations do
        operators builder
      end
    end
  end

  def operators(builder)
    companies.each do |company|
      Chouette::Netex::Operator.new(company).to_xml(builder)
    end
  end

  def companies
    @companies ||= referential.line_referential.companies
  end
end
