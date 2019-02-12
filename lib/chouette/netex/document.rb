class Chouette::Netex::Document
  include Chouette::Netex::Concerns::Helpers
  include Chouette::Netex::Concerns::EntityCollections
  include Chouette::Netex::Concerns::SourceCollections

  attr_accessor :referential

  def initialize(referential)
    @referential = referential
  end

  def build
    ActiveRecord::Base.cache do
      @builder = Nokogiri::XML::Builder.new(encoding: 'utf-8') do |xml|
        xml.PublicationDelivery(
          'xmlns'       => 'http://www.netex.org.uk/netex',
          'xmlns:xsi'   => 'http://www.w3.org/2001/XMLSchema-instance',
          'xmlns:gml'   => 'http://www.opengis.net/gml/3.2',
          'xmlns:siri'  => 'http://www.siri.org.uk/siri',
          'version'     => '1.04:NO-NeTEx-networktimetable:1.0'
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
  end

  def reset_xml
    @xml = nil
  end

  def to_xml
    @xml ||= @builder.to_xml
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

  def resource_frame(builder)
    return unless companies.exists?

    builder.ResourceFrame(version: :any, id: 'Chouette:ResourceFrame:1') do
      builder.organisations do
        netex_operators builder
      end
    end
  end

  def site_frame(builder)
    return unless stop_areas.exists?

    builder.SiteFrame(version: :any, id: 'Chouette:SiteFrame:1') do
      builder.stopPlaces do
        netex_stop_places builder
      end
    end
  end

  def service_frame(builder)
    return unless routes.exists? || lines.exists? || networks.exists?

    builder.ServiceFrame(version: :any, id: 'Chouette:ServiceFrame:1') do
      if routes.exists?
        builder.routePoints do
          netex_route_points builder
        end
        builder.routes do
          netex_routes builder
        end
        builder.scheduledStopPoints do
          netex_scheduled_stop_points builder
        end
        builder.stopAssignements do
          netex_stop_assignements builder
        end
      end
      if lines.exists?
        builder.lines do
          netex_lines builder
        end
      end
      if networks.exists?
        builder.groupsOfLines do
          netex_groups_of_lines builder
        end
      end
    end
  end

  def frames(builder)
    resource_frame(builder)
    site_frame(builder)
    service_frame(builder)
  end
end
