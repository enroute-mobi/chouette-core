class Merge < ApplicationModel
  extend Enumerize

  belongs_to :workbench
  validates :workbench, presence: true

  enumerize :status, in: %w[new pending successful failed running], default: :new

  has_array_of :referentials, class_name: 'Referential'

  delegate :output, to: :workbench

  after_commit :merge, :on => :create

  def merge
    MergeWorker.perform_async(id)
  end

  def name
    referentials.first(3).map { |r| r.name.truncate(10) }.join(',')
  end

  def full_names
    referentials.map(&:name).to_sentence
  end

  attr_reader :new

  def merge!
    update started_at: Time.now, status: :running

    prepare_new

    referentials.each do |referential|
      merge_referential referential
    end

    save_current
  rescue => e
    Rails.logger.error "Merge failed: #{e} #{e.backtrace.join("\n")}"
    update status: :failed
    new&.failed!
    raise e if Rails.env.test?
  ensure
    attributes = { ended_at: Time.now }
    if status == :running
      attributes[:status] = :successful
      referentials.each &:archived!
    end
    update attributes
  end

  def prepare_new
    new =
      if workbench.output.current
        Rails.logger.debug "Clone current output"
        Referential.new_from(workbench.output.current, workbench.organisation).tap do |clone|
          clone.inline_clone = true
        end
      else
        Rails.logger.debug "Create a new output"
        # 'empty' one
        attributes = {
          workbench: workbench,
          organisation: workbench.organisation, # TODO could be workbench.organisation by default
        }
        workbench.output.referentials.new attributes
      end

    new.referential_suite = output
    new.workbench = workbench
    new.organisation = workbench.organisation
    new.slug = "output_#{workbench.id}_#{created_at.to_i}"
    new.name = I18n.t("merges.referential_name", date: I18n.l(created_at))

    unless new.valid?
      Rails.logger.error "New referential isn't valid : #{new.errors.inspect}"
    end

    new.save!

    output.update new: new
    @new = new
  end

  def merge_referential(referential)
    Rails.logger.debug "Merge #{referential.slug}"

    metadata_merger = MetadatasMerger.new new, referential
    metadata_merger.merge

    new.metadatas.delete metadata_merger.empty_metadatas

    new.save!

    line_periods = LinePeriods.from_metadatas(referential.metadatas)

    new.switch do
      line_periods.each do |line_id, periods|
        Rails.logger.debug "Clean data for #{line_id} #{periods.inspect}"

        new.lines.find(line_id).time_tables.find_each do |time_table|
          time_table.remove_periods! periods
          unless time_table.empty?
            time_table.save!
          else
            time_table.destroy
          end
        end
      end
    end

    # let's merge data :)

    # Routes

    # Always the same pattern :
    # - load models from original Referential
    # - load associated datas (children, checksum for associated models)
    # - switch to new Referential
    # - enumerate loaded models
    # - skip model if its checksum exists "in the same line"
    # - prepare attributes for a fresh model
    # - remove all primary keys
    # - compute an ObjectId (TODO)
    # - process children models as nested attributes
    # - associated other models (by line/checksum)
    # - save! and next one

    referential_routes = referential.switch do
      referential.routes.all.to_a
    end

    referential_routes_checksums = Hash[referential_routes.map { |r| [ r.id, r.checksum ] }]

    referential_stop_points = referential.switch do
      referential.stop_points.all.to_a
    end

    referential_stop_points_by_route = referential_stop_points.group_by(&:route_id)

    referential_routing_constraint_zones = referential.switch do
      referential.routing_constraint_zones.each_with_object(Hash.new { |h,k| h[k] = {}}) do |routing_constraint_zone, hash|
        hash[routing_constraint_zone.route_id][routing_constraint_zone.checksum] = routing_constraint_zone
      end
    end

    referential_routing_constraint_zones_new_ids = {}

    new.switch do
      referential_routes.each do |route|
        existing_route = new.routes.find_by line_id: route.line_id, checksum: route.checksum
        if existing_route
          existing_route.merge_metadata_from route
        else
          objectid = Chouette::Route.where(objectid: route.objectid).exists? ? nil : route.objectid
          attributes = route.attributes.merge(
            id: nil,
            objectid: objectid,
            # line_id is the same
            # all other primary must be changed
            opposite_route_id: nil #FIXME
          )
          new_route = new.routes.build attributes

          route_stop_points = referential_stop_points_by_route[route.id]

          # Stop Points
          route_stop_points.sort_by(&:position).each do |stop_point|
            objectid = Chouette::StopPoint.where(objectid: stop_point.objectid).exists? ? nil : stop_point.objectid
            attributes = stop_point.attributes.merge(
              id: nil,
              route_id: nil,
              objectid: objectid,
            )
            new_route.stop_points.build attributes
          end

          # We need to create StopPoints to known new primary keys
          new_route.save!

          old_stop_point_ids = route_stop_points.sort_by(&:position).map(&:id)
          new_stop_point_ids = new_route.stop_points.sort_by(&:position).map(&:id)

          stop_point_ids_mapping = Hash[[old_stop_point_ids, new_stop_point_ids].transpose]

          # RoutingConstraintZones
          routing_constraint_zones = referential_routing_constraint_zones[route.id]

          routing_constraint_zones.values.each do |routing_constraint_zone|
            objectid = new.routing_constraint_zones.where(objectid: routing_constraint_zone.objectid).exists? ? nil : routing_constraint_zone.objectid
            stop_point_ids = routing_constraint_zone.stop_point_ids.map { |id| stop_point_ids_mapping[id] }.compact

            if stop_point_ids.size != routing_constraint_zone.stop_point_ids.size
              raise "Can't find all required StopPoints for RoutingConstraintZone #{routing_constraint_zone.inspect}"
            end

            attributes = routing_constraint_zone.attributes.merge(
              id: nil,
              route_id: nil,
              objectid: objectid,
              stop_point_ids: stop_point_ids,
            )
            new_route.routing_constraint_zones.build attributes

          end

          new_route.save!

          if new_route.checksum != route.checksum
            raise "Checksum has changed: \"#{route.checksum}\", \"#{route.checksum_source}\" -> \"#{new_route.checksum}\", \"#{new_route.checksum_source}\""
          end

          if new_route.routing_constraint_zones.map(&:checksum).sort != routing_constraint_zones.keys.sort
            raise "Checksum has changed in RoutingConstraintZones: \"#{new_route.routing_constraint_zones.map(&:checksum).sort}\" -> \"#{route.routing_constraint_zones.map(&:checksum).sort}\""
          end

          new_route.routing_constraint_zones.each do |new_routing_constraint_zone|
            routing_constraint_zone = routing_constraint_zones[new_routing_constraint_zone.checksum]
            if routing_constraint_zone
              referential_routing_constraint_zones_new_ids[routing_constraint_zone.id] = new_routing_constraint_zone.id
            else
              raise "Can't find RoutingConstraintZone for checksum #{new_routing_constraint_zone.checksum} into #{routing_constraint_zones.inspect}"
            end
          end
        end
      end
    end

    # JourneyPatterns

    referential_journey_patterns, referential_journey_patterns_stop_areas_objectids = referential.switch do
      journey_patterns = referential.journey_patterns.includes(stop_points: :stop_area)

      journey_patterns_stop_areas_objectids = Hash[
        journey_patterns.map do |journey_pattern|
          [ journey_pattern.id, journey_pattern.stop_points.map(&:stop_area).map(&:raw_objectid)]
        end
      ]

      [journey_patterns, journey_patterns_stop_areas_objectids]
    end

    referential_journey_patterns_checksums = Hash[referential_journey_patterns.map { |j| [ j.id, j.checksum ] }]

    new.switch do
      referential_journey_patterns.each do |journey_pattern|
        # find parent route by checksum
        # TODO add line_id for security
        associated_route_checksum = referential_routes_checksums[journey_pattern.route_id]
        existing_associated_route = new.routes.find_by checksum: associated_route_checksum

        existing_journey_pattern = new.journey_patterns.find_by route_id: existing_associated_route.id, checksum: journey_pattern.checksum

        if existing_journey_pattern
          existing_journey_pattern.merge_metadata_from journey_pattern
        else
          objectid = Chouette::JourneyPattern.where(objectid: journey_pattern.objectid).exists? ? nil : journey_pattern.objectid
          attributes = journey_pattern.attributes.merge(
            id: nil,
            objectid: objectid,

            # all other primary must be changed
            route_id: existing_associated_route.id,

            departure_stop_point_id: nil, # FIXME
            arrival_stop_point_id: nil
          )

          stop_areas_objectids = referential_journey_patterns_stop_areas_objectids[journey_pattern.id]

          stop_points = existing_associated_route.stop_points.joins(:stop_area).where("stop_areas.objectid": stop_areas_objectids).order(:position)
          if stop_points.count != stop_areas_objectids.count
            raise "Can't find StopPoints for #{stop_areas_objectids} : #{stop_points.inspect} #{existing_associated_route.stop_points.inspect}"
          end

          attributes.merge!(stop_points: stop_points)

          new_journey_pattern = new.journey_patterns.create! attributes
          if new_journey_pattern.checksum != journey_pattern.checksum
            raise "Checksum has changed for #{journey_pattern.inspect} (to #{new_journey_pattern.inspect}): \"#{journey_pattern.checksum_source}\" -> \"#{new_journey_pattern.checksum_source}\""
          end
        end
      end
    end

    # Vehicle Journeys

    referential_vehicle_journeys = referential.switch do
      referential.vehicle_journeys.includes(:vehicle_journey_at_stops).all.to_a
    end

    referential_purchase_windows_by_checksum, referential_vehicle_journey_purchase_window_checksums = referential.switch do
      purchase_windows_by_checksum = referential.purchase_windows.each_with_object({}) do |purchase_window, hash|
        hash[purchase_window.checksum] = purchase_window
      end

      vehicle_journey_purchase_window_checksums = Hash.new { |h,k| h[k] = [] }
      referential.purchase_windows.joins(:vehicle_journeys).pluck("vehicle_journeys.id", :checksum).each do |vehicle_journey_id, checksum|
        vehicle_journey_purchase_window_checksums[vehicle_journey_id] << checksum
      end

      [purchase_windows_by_checksum, vehicle_journey_purchase_window_checksums]
    end

    new_vehicle_journey_ids = {}

    new.switch do
      referential_vehicle_journeys.each do |vehicle_journey|
        # find parent journey pattern by checksum
        # TODO add line_id for security
        associated_route_checksum = referential_routes_checksums[vehicle_journey.route_id]
        associated_journey_pattern_checksum = referential_journey_patterns_checksums[vehicle_journey.journey_pattern_id]

        existing_associated_route = new.routes.find_by checksum: associated_route_checksum
        existing_associated_journey_pattern = existing_associated_route.journey_patterns.find_by checksum: associated_journey_pattern_checksum

        existing_vehicle_journey = new.vehicle_journeys.find_by journey_pattern_id: existing_associated_journey_pattern.id, checksum: vehicle_journey.checksum

        if existing_vehicle_journey
          existing_vehicle_journey.merge_metadata_from vehicle_journey
          new_vehicle_journey_ids[vehicle_journey.id] = existing_vehicle_journey.id
        else
          objectid = Chouette::VehicleJourney.where(objectid: vehicle_journey.objectid).exists? ? nil : vehicle_journey.objectid
          attributes = vehicle_journey.attributes.merge(
            id: nil,
            objectid: objectid,

            # all other primary must be changed
            route_id: existing_associated_journey_pattern.route_id,
            journey_pattern_id: existing_associated_journey_pattern.id,
            ignored_routing_contraint_zone_ids: []
          )
          new_vehicle_journey = new.vehicle_journeys.build attributes

          # Create VehicleJourneyAtStops

          vehicle_journey.vehicle_journey_at_stops.each_with_index do |vehicle_journey_at_stop, index|
            at_stop_attributes = vehicle_journey_at_stop.attributes.merge(
              id: nil,
              stop_point_id: existing_associated_journey_pattern.stop_points[index].id
            )
            new_vehicle_journey.vehicle_journey_at_stops.build at_stop_attributes
          end

          # Associate (and create if needed) PurchaseWindows

          referential_vehicle_journey_purchase_window_checksums[vehicle_journey.id].each do |purchase_window_checksum|
            associated_purchase_window = new.purchase_windows.find_by(checksum: purchase_window_checksum)

            unless associated_purchase_window
              purchase_window = referential_purchase_windows_by_checksum[purchase_window_checksum]

              objectid = new.purchase_windows.where(objectid: purchase_window.objectid).exists? ? nil : purchase_window.objectid
              attributes = purchase_window.attributes.merge(
                id: nil,
                objectid: objectid
              )
              new_purchase_window = new.purchase_windows.build attributes
              new_purchase_window.save!

              if new_purchase_window.checksum != purchase_window.checksum
                raise "Checksum has changed: #{purchase_window.checksum_source} #{new_purchase_window.checksum_source}"
              end

              associated_purchase_window = new_purchase_window
            end

            new_vehicle_journey.purchase_windows << associated_purchase_window
          end

          # Rewrite ignored_routing_contraint_zone_ids
          new_vehicle_journey.ignored_routing_contraint_zone_ids = referential_routing_constraint_zones_new_ids.values_at(*vehicle_journey.ignored_routing_contraint_zone_ids).compact
          new_vehicle_journey.save!

          if new_vehicle_journey.checksum != vehicle_journey.checksum
            raise "Checksum has changed: \"#{vehicle_journey.checksum_source}\" \"#{vehicle_journey.checksum}\" -> \"#{new_vehicle_journey.checksum_source}\" \"#{new_vehicle_journey.checksum}\""
          end

          new_vehicle_journey_ids[vehicle_journey.id] = new_vehicle_journey.id
        end

      end
    end

    # Time Tables

    referential_time_tables_by_id, referential_time_tables_with_lines = referential.switch do
      time_tables_by_id = Hash[referential.time_tables.includes(:dates, :periods).all.to_a.map { |t| [t.id, t] }]

      time_tables_with_associated_lines =
        referential.time_tables.joins(vehicle_journeys: {route: :line}).pluck("lines.id", :id, "vehicle_journeys.id")

      # Because TimeTables will be modified according metadata periods
      # we're loading timetables per line (line is associated to a period list)
      #
      # line_id: [ { time_table.id, vehicle_journey.checksum } ]
      time_tables_by_lines = time_tables_with_associated_lines.inject(Hash.new { |h,k| h[k] = [] }) do |hash, row|
        hash[row.shift] << {id: row.first, vehicle_journey_id: row.second}
        hash
      end

      [ time_tables_by_id, time_tables_by_lines ]
    end

    new.switch do
      referential_time_tables_with_lines.each do |line_id, time_tables_properties|
        # Because TimeTables will be modified according metadata periods
        # we're loading timetables per line (line is associated to a period list)
        line = workbench.line_referential.lines.find(line_id)

        time_tables_properties.each do |properties|
          time_table = referential_time_tables_by_id[properties[:id]]

          # we can't test if TimeTable already exist by checksum
          # because checksum is modified by intersect_periods!

          attributes = time_table.attributes.merge(
            id: nil,
            comment: "Ligne #{line.name} - #{time_table.comment}",
            calendar_id: nil
          )
          candidate_time_table = new.time_tables.build attributes

          time_table.dates.each do |date|
            date_attributes = date.attributes.merge(
              id: nil,
              time_table_id: nil
            )
            candidate_time_table.dates.build date_attributes
          end
          time_table.periods.each do |period|
            period_attributes = period.attributes.merge(
              id: nil,
              time_table_id: nil
            )
            candidate_time_table.periods.build period_attributes
          end

          candidate_time_table.intersect_periods! line_periods.periods(line_id)

          # FIXME
          candidate_time_table.set_current_checksum_source
          candidate_time_table.update_checksum

          # after intersect_periods!, the checksum is the expected one
          # we can search an existing TimeTable

          existing_time_table = line.time_tables.find_by checksum: candidate_time_table.checksum

          if existing_time_table
            existing_time_table.merge_metadata_from candidate_time_table
          else
            objectid = Chouette::TimeTable.where(objectid: time_table.objectid).exists? ? nil : time_table.objectid
            candidate_time_table.objectid = objectid

            candidate_time_table.save!

            # Checksum is changed by #intersect_periods
            # if new_time_table.checksum != time_table.checksum
            #   raise "Checksum has changed: #{time_table.checksum_source} #{new_time_table.checksum_source}"
            # end

            existing_time_table = candidate_time_table
          end

          # associate VehicleJourney

          new_vehicle_journey_id = new_vehicle_journey_ids[properties[:vehicle_journey_id]]
          unless new_vehicle_journey_id
            raise "TimeTable #{existing_time_table.inspect} associated to a not-merged VehicleJourney: #{properties[:vehicle_journey_id]}"
          end

          associated_vehicle_journey = line.vehicle_journeys.find(new_vehicle_journey_id)
          associated_vehicle_journey.time_tables << existing_time_table
        end
      end
    end
  end

  def save_current
    output.update current: new, new: nil
    output.current.update referential_suite: output, ready: true

    referentials.update_all merged_at: created_at, archived_at: created_at
  end

  def fixme_functional_scope
    if attribute = workbench.organisation.sso_attributes.try(:[], "functional_scope")
      JSON.parse(attribute)
    end
  end

  def child_change

  end

  class MetadatasMerger

    attr_reader :merge_metadatas, :referential
    def initialize(merge_referential, referential)
      @merge_metadatas = merge_referential.metadatas
      @referential = referential
    end

    delegate :metadatas, to: :referential, prefix: :referential

    def merge
      referential_metadatas.each do |metadata|
        merge_one metadata
      end
    end

    def merged_line_metadatas(line_id)
      merge_metadatas.select do |m|
        m.line_ids.include? line_id
      end
    end

    def merge_one(metadata)
      metadata.line_ids.each do |line_id|
        line_metadatas = merged_line_metadatas(line_id)

        metadata.periodes.each do |period|
          line_metadatas.each do |m|
            m.periodes = m.periodes.map do |existing_period|
              existing_period.remove period
            end.flatten
          end

          attributes = {
            line_ids: [line_id],
            periodes: [period],
            referential_source_id: referential.id,
            created_at: metadata.created_at # TODO check required dates
          }

          # line_metadatas should not contain conflicted metadatas
          merge_metadatas << ReferentialMetadata.new(attributes)
        end
      end
    end

    def empty_metadatas
      merge_metadatas.select { |m| m.periodes.empty? }
    end


  end

end
