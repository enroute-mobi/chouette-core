class Chouette::Netex::Document
  include Chouette::Netex::Helpers

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

  def frames(builder)
    builder.ResourceFrame(version: :any, id: 'Chouette:ResourceFrame:1') do
      builder.organisations do
        netex_operators builder
      end
    end
    builder.ResourceFrame(version: :any, id: 'Chouette:SiteFrame:1') do
      builder.stopPlaces do
        netex_stop_places builder
      end
    end
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
      builder.lines do
        netex_lines builder
      end
      builder.groupsOfLines do
        netex_groups_of_lines builder
      end
    end
  end

  def netex_operators(builder)
    Chouette::Company.within_workgroup(referential.workgroup) do
      companies.find_each do |company|
        Chouette::Netex::Operator.new(company).to_xml(builder)
      end
    end
  end

  def netex_stop_places(builder)
    Chouette::StopArea.within_workgroup(referential.workgroup) do
      stop_areas.where('stop_areas.area_type != ? OR stop_areas.parent_id IS NULL', :zdep).includes(:parent).find_each do |stop_area|
        Chouette::Netex::StopPlace.new(stop_area, stop_areas).to_xml(builder)
      end
    end
  end

  def netex_lines(builder)
    lines.find_each do |line|
      Chouette::Netex::Line.new(line).to_xml(builder)
    end
  end

  def netex_groups_of_lines(builder)
    networks.find_each do |network|
      Chouette::Netex::GroupOfLines.new(network).to_xml(builder)
    end
  end

  def netex_routes(builder)
    routes.find_each do |route|
      Chouette::Netex::Route.new(route).to_xml(builder)
    end
  end

  def netex_scheduled_stop_points(builder)
    stop_points.select(:id, :objectid).find_each do |stop_point|
      Chouette::Netex::ScheduledStopPoint.new(stop_point).to_xml(builder)
    end
  end

  def netex_stop_assignements(builder)
    stop_points.includes(:stop_area_light).find_each do |stop_point|
      Chouette::Netex::PassengerStopAssignment.new(stop_point).to_xml(builder)
    end
  end

  def netex_route_points(builder)
    stop_points.includes(:stop_area_light).find_each do |stop_point|
      Chouette::Netex::RoutePoint.new(stop_point).to_xml(builder)
    end
  end

  def companies
    @companies ||= referential.line_referential.companies
  end

  def stop_areas
    @stop_areas ||= referential.stop_area_referential.stop_areas
  end

  def lines
    @lines ||= referential.lines.includes(:network, :company_light)
  end

  def networks
    @networks ||= referential.line_referential.networks
  end

  def routes
    @routes ||= referential.routes
  end

  def stop_points
    @stop_points ||= referential.stop_points
  end
end
