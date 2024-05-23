class Merge::Referential::Legacy < Merge::Referential::Base

  def merge_metadata
    metadata_merger = Merge::Referential::MetadatasMerger.new new, referential
    metadata_merger.merge

    new.metadatas.delete metadata_merger.empty_metadatas

    new.save!
  end

  def line_periods
    @line_periods ||= LinePeriods.from_metadatas(referential.metadatas)
  end

  def merge!
    logger.tagged("Merge ##{merge.id}") do
      referential.switch do
        Chouette::ChecksumUpdater.new(referential).update
      end

      merge_metadata

      new.switch do
        line_periods.each do |line_id, periods|
          logger.debug "Clean data for #{line_id} #{periods.inspect}"

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

      code_spaces = workgroup.code_spaces.index_by(&:id)

      CustomFieldsSupport.within_workgroup workgroup do
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
        # - compute an ObjectId
        # - process children models as nested attributes
        # - associated other models (by line/checksum)
        # - save! and next one

        referential_stop_points = referential.switch do
          referential.stop_points.all.to_a
        end

        referential_stop_points_by_route = referential_stop_points.group_by(&:route_id)

        referential_routing_constraint_zones = referential.switch do
          referential.routing_constraint_zones.each_with_object(Hash.new { |h,k| h[k] = {}}) do |routing_constraint_zone, hash|
            hash[routing_constraint_zone.route_id][routing_constraint_zone.checksum] = routing_constraint_zone
          end
        end

        referential_route_opposite_route_ids = referential.switch do
          Hash[referential.routes.where('opposite_route_id is not null').pluck(:id, :opposite_route_id)]
        end

        new.switch do
          existing_route_objectids = new.routes.distinct.pluck(:objectid).to_set
          existing_stop_points_objectids = new.stop_points.distinct.pluck(:objectid).to_set

          route_ids_mapping = {}

          Chouette::Benchmark.measure("routes") do
            ApplicationModel.skipping_objectid_uniqueness do
              Chouette::StopPoint.acts_as_list_no_update do
                referential_routes.each_slice(100) do |routes|
                  Chouette::Route.transaction do
                    routes.each do |route|
                      Rails.logger.debug "Merge Route #{route.id}"
                      route_codes = ReferentialCode.unpersisted(route.codes, code_spaces: code_spaces)

                      existing_route = new.routes.find_by line_id: route.line_id, checksum: route.checksum
                      if existing_route
                        route_ids_mapping[route.id] = existing_route.id

                        existing_route.merge_metadata_from route
                        ReferentialCode.merge existing_route.codes, route_codes
                      else
                        objectid = existing_route_objectids.add?(route.objectid) ? route.objectid : nil
                        attributes = route.attributes.merge(
                          id: nil,
                          objectid: objectid,
                          codes: route_codes,
                          # line_id is the same
                          # all other primary must be changed
                          opposite_route_id: nil # merged after
                        )
                        new_route = new.routes.build attributes

                        route_stop_points = referential_stop_points_by_route[route.id] || []

                        # Stop Points
                        route_stop_points.sort_by(&:position).each do |stop_point|
                          objectid = existing_stop_points_objectids.add?(stop_point.objectid) ? stop_point.objectid : nil
                          attributes = stop_point.attributes.merge(
                            id: nil,
                            route_id: nil,
                            objectid: objectid,

                          )
                          stop_point = new_route.stop_points.build attributes
                          stop_point.skip_stop_area_id_validation
                        end

                        new_route.update_checksum_without_callbacks!(db_lookup: false)

                        # We need to create StopPoints to known new primary keys
                        save_model! new_route

                        route_ids_mapping[route.id] = new_route.id

                        old_stop_point_ids = route_stop_points.sort_by(&:position).map(&:id)
                        new_stop_point_ids = new_route.stop_points.sort_by(&:position).map(&:id)

                        stop_point_ids_mapping = Hash[[old_stop_point_ids, new_stop_point_ids].transpose]

                        # RoutingConstraintZones
                        routing_constraint_zones = referential_routing_constraint_zones[route.id]
                        if routing_constraint_zones.present?
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

                          new_route.update_checksum_without_callbacks!(db_lookup: false)
                          save_model! new_route
                        end

                        if new_route.checksum != route.checksum
                          raise "Checksum has changed for route #{route.id}:\n \"#{route.checksum}\", \"#{route.checksum_source}\" \n -> \n \"#{new_route.checksum}\", \"#{new_route.checksum_source}\""
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

                    referential_route_opposite_route_ids.each do |route_id, opposite_route_id|
                      new_route_id = route_ids_mapping[route_id]
                      new_opposite_route_id = route_ids_mapping[opposite_route_id]

                      new_route = nil
                      if new_route_id && new_opposite_route_id
                        if new_route = new.routes.find_by(id: new_route_id)
                          new_route.update_column :opposite_route_id, new_opposite_route_id
                        end
                        Rails.logger.warn "Can't merge opposite route for Route #{route_id}" unless new_route
                      end
                    end
                  end
                end
              end
            end
          end
        end

        # JourneyPatterns

        referential_journey_patterns_stop_areas_objectids = referential.switch do
          journey_patterns_stop_areas_objectids = {}

          referential.journey_patterns.includes(stop_points: :stop_area).find_each do |journey_pattern|
            journey_patterns_stop_areas_objectids[journey_pattern.id] = journey_pattern.stop_points.map { |sp| [sp.position, sp.stop_area.raw_objectid]}
          end

          journey_patterns_stop_areas_objectids
        end

        new.switch do
          existing_journey_pattern_objectids = new.journey_patterns.distinct.pluck(:objectid).to_set

          Chouette::Benchmark.measure("journey_patterns") do
            ApplicationModel.skipping_objectid_uniqueness do
              referential_journey_patterns.each_slice(100) do |journey_patterns|
                Chouette::JourneyPattern.transaction do
                  journey_patterns.each do |journey_pattern|
                    Rails.logger.debug "Merge Journey Pattern #{journey_pattern.id}"
                    journey_pattern_codes = ReferentialCode.unpersisted(journey_pattern.codes, code_spaces: code_spaces)

                    # find parent route by checksum
                    associated_line_id = referential_routes_lines[journey_pattern.route_id]
                    associated_route_checksum = referential_routes_checksums[journey_pattern.route_id]
                    existing_associated_route = new.routes.find_by checksum: associated_route_checksum, line_id: associated_line_id

                    existing_journey_pattern = new.journey_patterns.find_by route_id: existing_associated_route.id, checksum: journey_pattern.checksum

                    if existing_journey_pattern
                      existing_journey_pattern.merge_metadata_from journey_pattern
                      ReferentialCode.merge existing_journey_pattern.codes, journey_pattern_codes
                    else
                      objectid = existing_journey_pattern_objectids.add?(journey_pattern.objectid) ? journey_pattern.objectid : nil
                      attributes = journey_pattern.attributes.merge(
                        id: nil,
                        objectid: objectid,
                        codes: journey_pattern_codes,

                        # all other primary must be changed
                        route_id: existing_associated_route.id,

                        departure_stop_point_id: nil, # FIXME
                        arrival_stop_point_id: nil
                      )

                      stop_areas_objectids = referential_journey_patterns_stop_areas_objectids[journey_pattern.id]

                      # stop_points = stop_areas_objectids.map do |position, object_id|
                      #   existing_associated_route.stop_points.joins(:stop_area).where("stop_areas.objectid": object_id, position: position).last
                      # end.compact

                      stop_points = existing_associated_route.stop_points.includes(:stop_area).select do |stop_point|
                        stop_areas_objectids.find do |position, object_id|
                          position == stop_point.position && object_id == stop_point.stop_area.objectid
                        end
                      end

                      if stop_points.count != stop_areas_objectids.count
                        Rails.logger.info "Resolve stop points for JourneyPattern #{journey_pattern.checksum} by relative positions"
                        # If the absolute position values are not the same, we're looking for the StopPoints by relative position values
                        stop_areas_objectids.sort_by! { |position, _| position }

                        previous_position = -1
                        stop_points = stop_areas_objectids.map do |_, object_id|
                          stop_point = existing_associated_route.stop_points.joins(:stop_area).where("stop_areas.objectid": object_id).where('position > ?', previous_position).order(:position).first
                          unless stop_point
                            raise "Can't find StopPoint associated to #{object_id} with position > #{previous_position} in #{stop_areas_objectids} #{existing_associated_route.stop_points.inspect}"
                          end

                          previous_position = stop_point.position
                          stop_point
                        end.compact
                      end

                      attributes.merge!(stop_points: stop_points)

                      new_journey_pattern = new.journey_patterns.build
                      new_journey_pattern.skip_save_shortcuts
                      new_journey_pattern.attributes = attributes
                      new_journey_pattern.update_checksum_without_callbacks!(db_lookup: false)

                      save_model! new_journey_pattern

                      if new_journey_pattern.checksum != journey_pattern.checksum
                        raise "Checksum has changed for journey_pattern #{journey_pattern.inspect} (to #{new_journey_pattern.inspect}): \"#{journey_pattern.checksum_source}\" -> \"#{new_journey_pattern.checksum_source}\""
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end

      Chouette::ChecksumManager.inline do
        # Footnotes

        referential_footnotes = referential.switch do
          # All footnotes associated to a VehicleJourney are loaded
          referential.footnotes.associated.all.to_a
        end

        new.switch do
          referential_footnotes.each do |footnote|
            # If no footnote already exists in the same line with the same checksum
            existing_footnote = new.footnotes.find_by line_id: footnote.line_id, checksum: footnote.checksum
            if existing_footnote
              existing_footnote.merge_metadata_from footnote
            else
              attributes = footnote.attributes.merge(
                id: nil,
              )
              new_footnote = new.footnotes.build attributes

              save_model! new_footnote

              if new_footnote.checksum != footnote.checksum
                raise "Checksum has changed for footnote #{footnote.id} :\n \"#{footnote.checksum}\", \"#{footnote.checksum_source}\" \n -> \n \"#{new_footnote.checksum}\", \"#{new_footnote.checksum_source}\""
              end
            end
          end
        end

        # Vehicle Journeys

        merge_vehicle_journeys

        # Time Tables

        referential_time_tables_by_id, referential_time_tables_with_lines = referential.switch do
          Chouette::Benchmark.measure("load_time_tables") do
            time_tables_by_id = {}
            referential.time_tables.includes(:dates, :periods, :codes).find_each do |t|
              time_tables_by_id[t.id] = t
            end

            time_tables_with_associated_lines =
              referential.time_tables.joins(vehicle_journeys: {route: :line}).distinct.pluck("lines.id", :id, "vehicle_journeys.id")

            # Because TimeTables will be modified according metadata periods
            # we're loading timetables per line (line is associated to a period list)
            #
            # { line.id => { time_table.id => [ vehicle_journey.id, vehicle_journey.id ], ... }, ... }

            time_tables_by_lines = Hash.new do |h,line_id|
              h[line_id] = Hash.new { |h,time_table_id| h[time_table_id] = [] }
            end

            time_tables_with_associated_lines.each do |(line_id, time_table_id, vehicle_journey_id)|
              time_tables_by_lines[line_id][time_table_id] << vehicle_journey_id
            end

            [ time_tables_by_id, time_tables_by_lines ]
          end
        end

        new.switch do
          Chouette::Benchmark.measure("time_tables") do
            referential_time_tables_with_lines.each do |line_id, time_tables_with_vehicle_journey_ids|
              # Because TimeTables will be modified according metadata periods
              # we're loading timetables per line (line is associated to a period list)
              line = workbench.line_referential.lines.find(line_id)

              line_code = line.registration_number || line.objectid
              line_code = Netex::ObjectId.parse(line_code) || line_code

              Rails.logger.debug { "Merge Line #{line.id}/#{line.name}/#{line_code} #{time_tables_with_vehicle_journey_ids.size} Timetables" }

              # Merge all TimeTables associated with this Line .. by batch of 100
              time_tables_with_vehicle_journey_ids.each_slice(100) do |batch|
                Chouette::TimeTable.transaction do
                  batch.each do |time_table_id, vehicle_journey_ids|
                    time_table = referential_time_tables_by_id[time_table_id]
                    Rails.logger.debug { "Merge Timetable #{time_table.id} in Line #{line.id}/#{line.name}" }

                    timetable_codes = ReferentialCode.unpersisted(time_table.codes, code_spaces: code_spaces)

                    # As Timetables are duplicated for each Line, code values must be modified to distinct
                    # Merge line registration number in code value
                    timetable_codes.each do |timetable_code|
                      value =
                        if netex_identifier = Netex::ObjectId.parse(timetable_code.value)
                          # Something:Timetable:dummy:LOC -> Something:Timetable:dummy-AB:LOC
                          netex_identifier.merge(line_code).to_s
                        else
                          # dummy -> dummy-AB
                          [ timetable_code.value, line.registration_number ].join('-')
                        end
                      timetable_code.value = value
                    end

                    # we can't test if TimeTable already exist by checksum
                    # because checksum is modified by intersect_periods!

                    attributes = time_table.attributes.merge(
                      id: nil,
                      comment: "#{line.name} - #{time_table.comment}",
                      codes: timetable_codes,
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
                    next if candidate_time_table.empty?

                    # FIXME
                    candidate_time_table.set_current_checksum_source
                    candidate_time_table.update_checksum

                    # after intersect_periods!, the checksum is the expected one
                    # we can search an existing TimeTable

                    existing_time_table = line.time_tables.find_by checksum: candidate_time_table.checksum

                    if existing_time_table
                      Rails.logger.debug "Find existing TimeTable #{existing_time_table.id} for #{candidate_time_table.checksum}"
                      existing_time_table.merge_metadata_from candidate_time_table
                      ReferentialCode.merge existing_time_table.codes, timetable_codes
                    else
                      Rails.logger.debug "Create new TimeTable for #{candidate_time_table.checksum}"
                      objectid = Chouette::TimeTable.where(objectid: time_table.objectid).exists? ? nil : time_table.objectid
                      candidate_time_table.objectid = objectid

                      save_model! candidate_time_table

                      existing_time_table = candidate_time_table
                    end

                    # associate VehicleJourneys with this TimeTable
                    new_vehicle_journey_ids = vehicle_journey_ids.map do |vehicle_journey_id|
                      new_vehicle_journey_id = existing_vehicle_journey_ids[vehicle_journey_id]
                      unless new_vehicle_journey_id
                        raise "TimeTable #{existing_time_table.inspect} associated to a not-merged VehicleJourney: #{vehicle_journey_id}"
                      end
                      new_vehicle_journey_id
                    end

                    existing_time_table.vehicle_journeys << line.vehicle_journeys.find(new_vehicle_journey_ids)
                  end
                end
              end
            end
          end
        end
      end
    end
  end

  def existing_vehicle_journey_ids
    @existing_vehicle_journey_ids ||= Hash[
      referential.switch do
        referential.vehicle_journeys.joins(:journey_pattern, :route).
          joins("INNER JOIN \"#{new.slug}\".vehicle_journeys as existing_vehicle_journeys ON vehicle_journeys.checksum = existing_vehicle_journeys.checksum").
          joins("INNER JOIN \"#{new.slug}\".journey_patterns as existing_journey_patterns ON journey_patterns.checksum = existing_journey_patterns.checksum AND existing_journey_patterns.id = existing_vehicle_journeys.journey_pattern_id").
          joins("INNER JOIN \"#{new.slug}\".routes as existing_routes ON routes.checksum = existing_routes.checksum and routes.line_id = existing_routes.line_id AND existing_routes.id = existing_journey_patterns.route_id").
          pluck(:id, 'existing_vehicle_journeys.id')
      end
    ]
  end

  def vehicle_journeys_batch_size
    100
  end

  def legacy_merge_vehicle_journeys(referential_vehicle_journeys)
    referential_vehicle_journey_footnote_checksums = {}
    referential_vehicle_journey_codes = Hash.new { |h,k| h[k] = [] }

    referential.switch do
      referential_vehicle_journeys.each do |vehicle_journey|
        referential_vehicle_journey_footnote_checksums[vehicle_journey.id] = vehicle_journey.footnotes.pluck(:checksum)
        referential_vehicle_journey_codes[vehicle_journey.id] = vehicle_journey.codes.pluck(:code_space_id, :value)
      end
    end

    new.switch do
      Chouette::VehicleJourney.transaction do
        referential_vehicle_journeys.each do |vehicle_journey|
          # find parent journey pattern by checksum
          associated_line_id = referential_routes_lines[vehicle_journey.route_id]
          associated_route_checksum = referential_routes_checksums[vehicle_journey.route_id]
          associated_journey_pattern_checksum = referential_journey_patterns_checksums[vehicle_journey.journey_pattern_id]

          existing_associated_route = new.routes.find_by checksum: associated_route_checksum, line_id: associated_line_id
          existing_associated_journey_pattern = existing_associated_route.journey_patterns.find_by checksum: associated_journey_pattern_checksum

          existing_vehicle_journey = new.vehicle_journeys.find_by journey_pattern_id: existing_associated_journey_pattern.id, checksum: vehicle_journey.checksum

          merged_vehicle_journey = nil

          if existing_vehicle_journey
            existing_vehicle_journey.merge_metadata_from vehicle_journey
            new_vehicle_journey_ids[vehicle_journey.id] = existing_vehicle_journey.id
            merged_vehicle_journey = existing_vehicle_journey
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
                stop_point_id: existing_associated_journey_pattern.stop_points[index].id,
                # we need this to prevent the ChecksumManager from spawning another instance of the VehicleJourney
                # Yes, this should be handled by Rails. No, we won't upograde Rails just for that :)
                vehicle_journey: new_vehicle_journey
              )
              new_vehicle_journey.vehicle_journey_at_stops.build at_stop_attributes
            end

            # Associate Footnotes
            referential_vehicle_journey_footnote_checksums[vehicle_journey.id].each do |footnote_checksum|
              associated_footnote = new.footnotes.find_by(line_id: associated_line_id, checksum: footnote_checksum)
              new_vehicle_journey.footnotes << associated_footnote
            end

            # Rewrite ignored_routing_contraint_zone_ids
            new_vehicle_journey.ignored_routing_contraint_zone_ids = referential_routing_constraint_zones_new_ids.values_at(*vehicle_journey.ignored_routing_contraint_zone_ids).compact
            save_model! new_vehicle_journey

            if new_vehicle_journey.checksum != vehicle_journey.checksum
              logger.info "failing vehicle journey:"
              logger.info "before:"
              logger.info vehicle_journey.inspect
              vehicle_journey.vehicle_journey_at_stops.each do |vjas|
                logger.info vjas.inspect
              end

              logger.info "after:"
              logger.info new_vehicle_journey.inspect
              new_vehicle_journey.vehicle_journey_at_stops.each do |vjas|
                logger.info vjas.inspect
              end

              raise "Checksum has changed for vehicle_journey #{vehicle_journey.id} :\n \"#{vehicle_journey.checksum_source}\" \n - \"#{vehicle_journey.checksum}\" \n => \n \"#{new_vehicle_journey.checksum_source}\"  \n - \"#{new_vehicle_journey.checksum}\""
            end

            new_vehicle_journey_ids[vehicle_journey.id] = new_vehicle_journey.id
            merged_vehicle_journey = new_vehicle_journey
          end

          referential_vehicle_journey_codes[vehicle_journey.id].each do |code_space_id, code_value|
            # rescue ActiveRecord::RecordNotUnique doesn't work.
            # PostgreSQL rollbacks the whole transaction on duplicate record.
            # See CHOUETTE-573
            merged_vehicle_journey.codes.find_or_create_by code_space_id: code_space_id, value: code_value
          end
        end
      end
    end
  end

  def save_model!(model)
    unless model.save
      logger.info "Can't save #{model.class.name} : #{model.errors.inspect}"
      raise ActiveRecord::RecordNotSaved, "Invalid #{model.class.name} : #{model.errors.inspect}"
    end
    logger.debug { "Created #{model.inspect}" }
  end

  def new_vehicle_journey_ids
    @new_vehicle_journey_ids ||= {}
  end

  def referential_routes
    @referential_routes ||= referential.switch do
      Chouette::Benchmark.measure("load_routes") do
        referential.routes.includes(:codes).all.to_a
      end
    end
  end

  def referential_routes_checksums
    @referential_routes_checksums ||= Hash[referential_routes.map { |r| [ r.id, r.checksum ] }]
  end

  def referential_routes_lines
    @referential_routes_lines ||= Hash[referential_routes.map { |r| [ r.id, r.line_id ] }]
  end

  def referential_journey_patterns
    @referential_journey_patterns ||= referential.switch do
      Chouette::Benchmark.measure("load_journey_patterns") do
        referential.journey_patterns.includes(:codes).all.to_a
      end
    end
  end

  def referential_journey_patterns_checksums
    @referential_journey_patterns_checksums ||= Hash[referential_journey_patterns.map { |j| [ j.id, j.checksum ] }]
  end

  def referential_routing_constraint_zones_new_ids
    @referential_routing_constraint_zones_new_ids ||= {}
  end

  def merge_vehicle_journeys
    referential.switch do
      batch = 0
      Chouette::Benchmark.measure("vehicle_journeys") do
        referential.vehicle_journeys.includes(:vehicle_journey_at_stops, :footnotes, :codes).find_in_batches(batch_size: vehicle_journeys_batch_size) do |referential_vehicle_journeys|
          batch += 1
          Chouette::Benchmark.measure("batch", batch: batch) do
            legacy_merge_vehicle_journeys referential_vehicle_journeys
          end
        end
      end
    end

    unless existing_vehicle_journey_ids == new_vehicle_journey_ids
      logger.error("existing_vehicle_journey_ids: #{existing_vehicle_journey_ids.inspect}")
      logger.error("new_vehicle_journey_ids: #{new_vehicle_journey_ids.inspect}")
      raise "Invalid new_vehicle_journey_ids"
    end
  end

end
