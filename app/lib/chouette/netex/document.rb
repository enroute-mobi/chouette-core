module NetexDocumentWithLog
  def node_if_content name, &block
    Rails.logger.info "NETEX Export: #{name}"
    super name, &block
  end
end

class Chouette::Netex::Document
  prepend NetexDocumentWithLog

  include Chouette::Netex::Concerns::Helpers
  include Chouette::Netex::Concerns::EntityCollections
  include Chouette::Netex::Concerns::SourceCollections

  attr_accessor :referential

  def initialize(export)
    @referential = export.referential
    @export = export
  end

  def build
    referential.switch do
      ActiveRecord::Base.cache do
        @document = Nokogiri::XML::Builder.new(encoding: 'utf-8') do |xml|
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
  end

  def document
    @document ||= build && @document
  end

  def reset_xml
    @xml = nil
  end

  def to_xml
    @xml ||= document.to_xml
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

  def log_warning(key, attrs={})
    @export.messages.create({
      criticity: :warning,
      message_attributes: attrs,
      message_key: key
    })
  end

  protected

  def resource_frame
    return unless companies.exists?

    @builder.ResourceFrame(version: :any, id: 'Chouette:ResourceFrame:1') do
      node_if_content :organisations do
        netex_operators
      end
    end
  end

  def site_frame
    return unless stop_areas.exists?

    @builder.SiteFrame(version: :any, id: 'Chouette:SiteFrame:1') do
      node_if_content :stopPlaces do
        netex_stop_places
      end
    end
  end

  def service_frame
    return unless routes.exists? || lines.exists? || networks.exists?

    @builder.ServiceFrame(version: :any, id: 'Chouette:ServiceFrame:1') do
      node_if_content :routePoints do
        netex_route_points
      end
      node_if_content :routes do
        netex_routes
      end
      node_if_content :lines do
        netex_lines
      end
      node_if_content :groupsOfLines do
        netex_groups_of_lines
      end
      node_if_content :scheduledStopPoints do
        netex_scheduled_stop_points
      end
      node_if_content :serviceLinks do
        netex_service_links
      end
      node_if_content :stopAssignments do
        netex_stop_assignments
      end
      node_if_content :journeyPatterns do
        netex_service_journey_patterns
      end
      node_if_content :routingConstraintZones do
        netex_routing_constraint_zones
      end
    end
  end

  def timetable_frame
    @builder.TimetableFrame(version: :any, id: 'Chouette:TimetableFrame:1') do
      node_if_content :vehicleJourneys do
        netex_service_journeys
      end
    end
  end

  def service_calendar_frame
    @builder.ServiceCalendarFrame(version: :any, id: 'Chouette:SiteFrame:1', created: format_time(Time.now), changed: format_time(Time.now)) do
      if referential.circulation_start && referential.circulation_end
        @builder.ServiceCalendar(version: :any, id: 'Chouette:ServiceCalendar:1') do
          @builder.FromDate referential.circulation_start
          @builder.ToDate referential.circulation_end
        end
      end
      node_if_content :dayTypes do
        netex_day_types
      end
      node_if_content :operatingPeriods do
        netex_operating_periods
      end
      node_if_content :dayTypeAssignments do
        netex_day_type_assignments
      end
    end
  end

  def frames(builder)
    @builder = builder
    netex_frames :resource, :site, :service, :timetable, :service_calendar
    @builder = nil
  end

  def netex_frames *frame
    frame.each &method(:netex_frame)
  end

  def netex_frame name
    Chouette::Benchmark.log "NETEX FULL EXPORT: #{name} frame" do
      send("#{name}_frame")
    end
  end

  def workgroup
    @workgroup ||= referential.workgroup
  end
end
