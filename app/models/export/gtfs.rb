class Export::GTFS < Export::Base
  require "zip"
  require "google/cloud/storage"

  after_commit :launch_worker, :on => :create

  option :duration, required: true, type: :integer, default_value: 200

  def launch_worker
    GTFSExportWorker.perform_async(id)
  end

  # def new_child klass
  #   exporter = klass.new
  #   yield exporter
  #   exporter.parent = self
  #   exporter.workbench = self.workbench
  #   exporter.creator = self.creator
  #   exporter.referential_id = self.referential_id
  #   exporter.synchronous = true
  #   exporter.save!
  # end

  def zip_file_name
    "chouette-its-#{Time.now.to_i}"
  end

  def make_zip
    tmp_dir = Dir.mktmpdir
    zip_file = File.new(File.join(tmp_dir, "#{zip_file_name}.zip"), 'w+')

    # Initialize the temp file as a zip file to make Zip::File.open happy
    Zip::OutputStream.open(zip_file.path) { |zos| }

    Zip::File.open(zip_file.path, Zip::File::CREATE) do |child_file|
      self.children.each do |child|
        filepath = child.filepath
        next if File.basename(filepath) == "od_pair.json" && ENV["OUIBUS_EXPORT_ODPAIRS"] != "true"
        next if File.basename(filepath) == "sales_restriction.json" && ENV["OUIBUS_EXPORT_SALESRESTRICTIONS"] != "true"

        child_file.add(File.basename(filepath), filepath) if filepath
      end
    end
    zip_file
  end


  def export
    referential.switch


    journeys = Chouette::VehicleJourney.with_matching_timetable (Time.now.to_date..self.duration.to_i.days.from_now.to_date)
    journey_ids = journeys.pluck(:id).uniq

    # if journeys.count == 0
    #   self.update status: :successful
    #   vals = {}
    #   vals[:criticity] = :info
    #   vals[:message_key] = :no_matching_journey
    #   self.messages.create vals
    #   return
    # end

    tmp_dir = Dir.mktmpdir

    GTFS::Target.open(File.join(tmp_dir, "#{zip_file_name}.zip")) do |target|
      # Export Chouette::Companies -> GTFS::Agencies
      company_ids = journeys.pluck :company_id
      company_ids += journeys.joins(route: :line).pluck :"lines.company_id"
      Chouette::Company.where(id: company_ids.uniq).order('name').each do |company|
        target.agencies << {
          id: company.registration_number,
          name: company.name,
          url: company.url,
          timezone: company.time_zone,
          phone: company.phone,
          email: company.email
          #lang: TO DO
          #fare_url: TO DO
        }
      end

      # Export Stops
      stop_ids = Chouette::StopArea.where(id: journeys.joins(route: :stop_points).pluck(:"stop_points.stop_area_id").uniq).pluck(:id).uniq
      Chouette::StopArea.where(id: stop_ids).order('parent_id ASC NULLS FIRST').each do |stop_area|
        target.stops << {
          id: stop_area.registration_number,
          name: stop_area.name,
          location_type: stop_area.area_type == 'zdlp' ? 1 : 0,
          parent_station: stop_area.parent.try(:registration_number),
          lat: stop_area.latitude,
          lon: stop_area.longitude,
          desc: stop_area.comment,
          url: stop_area.url,
          timezone: stop_area.time_zone
          #code: TO DO
          #wheelchair_boarding: TO DO wheelchair_boarding <=> mobility_restricted_suitability ?
        }
      end

      # Export Routes
      line_ids = journeys.joins(:route).pluck :line_id
      Chouette::Line.where(id: line_ids.uniq).each do |line|
        target.routes << {
          id: line.registration_number,
          agency_id: line.company.registration_number,
          long_name: line.published_name,
          short_name: line.number,
          type: line.gtfs_type,
          desc: line.comment,
          url: line.url
          #color: TO DO
          #text_color: TO DO
        }
      end

      # Export Calendar
      journey_pattern_ids = journeys.pluck :journey_pattern_id
      time_tables_ids = Chouette::TimeTable.join(vehicle_journeys).where (vehicle_journeys: {id: journey_pattern_ids}).pluck :id
      Chouette::TimeTable.where(id: time_tables_ids.uniq).each do |time_table|
        target.calendars << {
          service_id: ,
          start_date: ,
          end_date:,
          monday:,
          tuesday:,
          wednesday:,
          thursday:,
          friday:,
          saturday:,
          sunday:
        }
      end

      # Export Trips
      journey_pattern_ids = journeys.pluck :journey_pattern_id
      Chouette::JourneyPattern.where(id: journey_pattern_ids.uniq).each do |route|
        target.trips << {
          route_id: route.line.registration_number,
          #service_id:  TO DO timetable,
          #id: TO DO + store that field at import
          #headsign: TO DO + store that field at import
          #short_name: TO DO + store that field at import
          direction_id: route.wayback == :outbound ? 0 : 1,
          desc: line.comment,
          url: line.url,
          #block_id: TO DO
          #wheelchair_accessible: TO DO
          #bikes_allowed: TO DO
        }
      end
    end
  end





  new_child Export::SimpleExporter::SqillsSchedules do |exporter|
    exporter._journey_ids = journey_ids
    exporter.duration = duration
    exporter.name = "Export Schedules of Referential #{self.referential.name} over #{self.duration} days"
  end

  new_child Export::SimpleExporter::SqillsRoutes do |exporter|
    exporter.journey_pattern_ids = journeys.pluck(:journey_pattern_id).uniq
    exporter.name = "Export Routes of Referential #{self.referential.name} over #{self.duration} days"
  end

  new_child Export::SimpleExporter::SqillsStopAreas do |exporter|
    stops = Chouette::StopArea.where(id: journeys.joins(route: :stop_points).pluck(:"stop_points.stop_area_id").uniq).order('parent_id ASC NULLS FIRST')
    if Chouette::StopArea.column_names.include?("non_commercial_area_type")
      stops = stops.where("area_type IN (?) OR non_commercial_area_type = ?", Chouette::AreaType.commercial, "border")
    else
      types = Chouette::AreaType.commercial
      types << "border"
      stops = stops.where(area_type: types)
    end
    exporter.stop_ids = stops.pluck(:id).uniq
    exporter.name = "Export Stops of Referential #{self.referential.name} over #{self.duration} days"
  end

  new_child Export::SimpleExporter::SqillsOdPairs do |exporter|
    stop_point_ids = journeys.joins(route: :stop_points).pluck(:"stop_points.id").uniq
    exporter._stop_point_ids = stop_point_ids
    exporter._journey_ids = journey_ids
    exporter.name = "Export OD Pairs of Referential #{self.referential.name} over #{self.duration} days"
  end

  new_child Export::SimpleExporter::SqillsJourneys do |exporter|
    exporter._journey_ids = journey_ids
    exporter.duration = duration
    exporter.name = "Export Services of Referential #{self.referential.name} over #{self.duration} days"
  end

  new_child Export::SimpleExporter::SqillsSalesRestrictions do |exporter|
    exporter._journey_ids = journey_ids
    exporter.duration = duration
    exporter.name = "Export Sales Restrictions of Referential #{self.referential.name} over #{self.duration} days"
  end

  save!
  zip_file = make_zip
  upload_file zip_file
end

def export_agencies
  line_referential.companies.all.map()
end

end
