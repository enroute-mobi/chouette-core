class Merge < ApplicationModel
  include OperationSupport
  include NotifiableSupport

  belongs_to :workbench

  validates :workbench, presence: true

  has_many :compliance_check_sets, -> { where(parent_type: "Merge") }, foreign_key: :parent_id, dependent: :destroy

  delegate :output, to: :workbench

  delegate :workgroup, to: :workbench

  def parent
    workbench
  end

  def is_current?
    new_id == workbench.output.current_id
  end

  def rollback!
    raise "You cannot rollback to the current version" if current?
    workbench.output.update current: self.new
    self.following_merges.each(&:cancel!)
  end

  def cancel!
    update status: :canceled
    referentials.each(&:unmerged!)
    new&.rollbacked!
  end

  def following_merges
    following_referentials = self.workbench.output.referentials.where('created_at > ?', self.new.created_at)
    workbench.merges.where(new_id: following_referentials.pluck(:id))
  end

  def merge
    # Step 1 : Before
    update_column :started_at, Time.now
    update_column :status, :running

    referentials.each(&:pending!)

    if before_merge_compliance_control_sets.present?
      create_before_merge_compliance_check_sets
    else
      enqueue_job :merge!
    end
  end
  alias run merge

  def before_merge_compliance_control_sets
    workbench.workgroup.before_merge_compliance_control_sets.map do |key, _|
      cc_set = workbench.compliance_control_set(key)
      cc_set.present? ? [key, cc_set] : nil
    end.compact
  end

  def after_merge_compliance_control_sets
    workbench.workgroup.after_merge_compliance_control_sets.map do |key, _|
      cc_set = workbench.compliance_control_set(key)
      cc_set.present? ? [key, cc_set] : nil
    end.compact
  end

  def create_before_merge_compliance_check_sets
    referentials.each do |referential|
      before_merge_compliance_control_sets.each do |key, compliance_control_set|
        create_compliance_check_set key, compliance_control_set, referential
      end
    end
  end

  def create_after_merge_compliance_check_sets
    after_merge_compliance_control_sets.each do |key, compliance_control_set|
      create_compliance_check_set key, compliance_control_set, new
    end
  end

  def merge!
    CustomFieldsSupport.within_workgroup(workgroup) do
      Chouette::Benchmark.measure("merge", merge: id) do
        Chouette::Benchmark.measure("prepare_new") do
          prepare_new
        end

        referentials.each do |referential|
          Chouette::Benchmark.measure("referential", referential: referential.id) do
            merge_referential referential
          end
        end

        Chouette::Benchmark.measure("clean_new") do
          clean_new
        end

        if after_merge_compliance_control_sets.present?
          create_after_merge_compliance_check_sets
        else
          save_current
        end
      end
    end
  rescue => e
    Rails.logger.error "Merge ##{id} failed: #{e} #{e.backtrace.join("\n")}"
    failed!
    raise e# if Rails.env.test?
  end

  def prepare_new
    new =
      if workbench.output.current
        Rails.logger.debug "Merge ##{id}: Clone current output"
        Referential.new_from(workbench.output.current, workbench).tap do |clone|
          clone.inline_clone = true
        end
      else
        if workbench.merges.successful.count > 0
          # there had been previous merges, we should have a current output
          raise "Trying to create a new referential to merge into from Merge##{self.id}, while there had been previous merges in the same workbench"
        end
        Rails.logger.debug "Merge ##{id}: Create a new output"
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
    new.name = I18n.t("merges.referential_name", date: I18n.l(created_at, format: :short_with_time))

    unless new.valid?
      Rails.logger.error "Merge ##{id}: New referential isn't valid : #{new.errors.inspect}"
    end

    begin
      new.save!
    rescue
      Rails.logger.debug "Merge ##{id}: Errors on new referential: #{new.errors.messages}"
      raise
    end

    new.metadatas.reload
    new.flag_not_urgent!
    new.pending!

    output.update new: new
    update new: new
  end

  def clean_new
    CleanUp.new(referential: new, clean_methods: [:clean_irrelevant_data, :clean_unassociated_calendars]).clean
  end

  def merge_referential_metadata(referential)
    metadata_merger = MetadatasMerger.new new, referential
    metadata_merger.merge

    new.metadatas.delete metadata_merger.empty_metadatas

    new.save!
  end

  def merge_referential(referential)
    Rails.logger.debug "Merge ##{id}: Merge #{referential.slug}"

    merge_referential_metadata(referential)

    line_periods = LinePeriods.from_metadatas(referential.metadatas)

    new.switch do
      line_periods.each do |line_id, periods|
        Rails.logger.debug "Merge ##{id}: Clean data for #{line_id} #{periods.inspect}"

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
    # - compute an ObjectId
    # - process children models as nested attributes
    # - associated other models (by line/checksum)
    # - save! and next one

    referential_routes = referential.switch do
      Chouette::Benchmark.measure("load_routes") do
        referential.routes.all.to_a
      end
    end

    referential_routes_checksums = Hash[referential_routes.map { |r| [ r.id, r.checksum ] }]

    referential_routes_lines = Hash[referential_routes.map { |r| [ r.id, r.line_id ] }]

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

    referential_routing_constraint_zones_new_ids = {}

    new.switch do
      route_ids_mapping = {}

      Chouette::Benchmark.measure("routes") do
        referential_routes.each_slice(10) do |routes|
          Chouette::Route.transaction do
            routes.each do |route|
              existing_route = new.routes.find_by line_id: route.line_id, checksum: route.checksum
              if existing_route
                route_ids_mapping[route.id] = existing_route.id
                existing_route.merge_metadata_from route
              else
                objectid = Chouette::Route.where(objectid: route.objectid).exists? ? nil : route.objectid
                attributes = route.attributes.merge(
                  id: nil,
                  objectid: objectid,
                  # line_id is the same
                  # all other primary must be changed
                  opposite_route_id: nil # merged after
                )
                new_route = new.routes.build attributes

                route_stop_points = referential_stop_points_by_route[route.id] || []

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
                save_model! new_route

                route_ids_mapping[route.id] = new_route.id

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

                save_model! new_route

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
                Rails.logger.warn "Merge ##{id}: Can't merge opposite route for Route #{route_id}" unless new_route
              end
            end
          end
        end
      end
    end

    # JourneyPatterns

    referential_journey_patterns, referential_journey_patterns_stop_areas_objectids = referential.switch do
      Chouette::Benchmark.measure("load_journey_patterns") do
        journey_patterns = referential.journey_patterns

        journey_patterns_stop_areas_objectids = {}
        journey_patterns.includes(stop_points: :stop_area).find_each do |journey_pattern|
          journey_patterns_stop_areas_objectids[journey_pattern.id] = journey_pattern.stop_points.map { |sp| [sp.position, sp.stop_area.raw_objectid]}
        end

        [journey_patterns.to_a, journey_patterns_stop_areas_objectids]
      end
    end

    referential_journey_patterns_checksums = {}
    referential_journey_patterns.each { |j| referential_journey_patterns_checksums[j.id] = j.checksum }

    new.switch do
      Chouette::Benchmark.measure("journey_patterns") do
        referential_journey_patterns.each_slice(20) do |journey_patterns|
          Chouette::JourneyPattern.transaction do
            journey_patterns.each do |journey_pattern|
              # find parent route by checksum
              associated_line_id = referential_routes_lines[journey_pattern.route_id]
              associated_route_checksum = referential_routes_checksums[journey_pattern.route_id]
              existing_associated_route = new.routes.find_by checksum: associated_route_checksum, line_id: associated_line_id

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

                stop_points = stop_areas_objectids.map do |position, object_id|
                  existing_associated_route.stop_points.joins(:stop_area).where("stop_areas.objectid": object_id, position: position).last
                end
                if stop_points.count != stop_areas_objectids.count
                  raise "Can't find StopPoints for #{stop_areas_objectids} : #{stop_points.inspect} #{existing_associated_route.stop_points.inspect}"
                end

                attributes.merge!(stop_points: stop_points)

                new_journey_pattern = new.journey_patterns.create! attributes
                if new_journey_pattern.checksum != journey_pattern.checksum
                  raise "Checksum has changed for journey_pattern #{journey_pattern.inspect} (to #{new_journey_pattern.inspect}): \"#{journey_pattern.checksum_source}\" -> \"#{new_journey_pattern.checksum_source}\""
                end
              end
            end
          end
        end
      end
    end

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
    new_vehicle_journey_ids = {}

    referential.switch do
      batch = 0
      Chouette::Benchmark.measure("vehicle_journeys") do
        referential.vehicle_journeys.includes(:vehicle_journey_at_stops, :purchase_windows, :footnotes).find_in_batches(batch_size: vehicle_journeys_batch_size) do |referential_vehicle_journeys|
          batch += 1
          Chouette::Benchmark.measure("batch", batch: batch) do
            merge_vehicle_journeys referential, referential_vehicle_journeys, new_vehicle_journey_ids, referential_routes_lines, referential_routes_checksums, referential_journey_patterns_checksums, referential_routing_constraint_zones_new_ids
          end
        end
      end
    end

    # Time Tables

    referential_time_tables_by_id, referential_time_tables_with_lines = referential.switch do
      Chouette::Benchmark.measure("load_time_tables") do
        time_tables_by_id = {}
        referential.time_tables.includes(:dates, :periods).find_each do |t|
          time_tables_by_id[t.id] = t
        end

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
    end

    new.switch do
      Chouette::Benchmark.measure("time_tables") do
        referential_time_tables_with_lines.each do |line_id, time_tables_properties|
          # Because TimeTables will be modified according metadata periods
          # we're loading timetables per line (line is associated to a period list)
          line = workbench.line_referential.lines.find(line_id)

          time_tables_properties.each_slice(30) do |batch|
            Chouette::TimeTable.transaction do
              batch.each do |properties|
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
                unless candidate_time_table.empty?

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

                    save_model! candidate_time_table

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
        end
      end
    end
  end

  def vehicle_journeys_batch_size
    100
  end

  def merge_vehicle_journeys(referential, referential_vehicle_journeys, new_vehicle_journey_ids, referential_routes_lines, referential_routes_checksums, referential_journey_patterns_checksums, referential_routing_constraint_zones_new_ids)
    referential_purchase_windows_by_checksum = {}
    referential_vehicle_journey_purchase_window_checksums = Hash.new { |h,k| h[k] = [] }
    referential_vehicle_journey_footnote_checksums = {}

    referential.switch do
      referential_vehicle_journeys.each do |vehicle_journey|
        vehicle_journey.purchase_windows.each do |purchase_window|
          referential_purchase_windows_by_checksum[purchase_window.checksum] = purchase_window
          referential_vehicle_journey_purchase_window_checksums[vehicle_journey.id] << purchase_window.checksum
        end
        referential_vehicle_journey_footnote_checksums[vehicle_journey.id] = vehicle_journey.footnotes.pluck(:checksum)
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
                stop_point_id: existing_associated_journey_pattern.stop_points[index].id,
                # we need this to prevent the ChecksumManager from spawning another instance of the VehicleJourney
                # Yes, this should be handled by Rails. No, we won't upograde Rails just for that :)
                vehicle_journey: new_vehicle_journey
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
                save_model! new_purchase_window

                if new_purchase_window.checksum != purchase_window.checksum
                  raise "Checksum has changed for purchase_window #{purchase_window.id} :\n #{purchase_window.checksum_source} \n => \n #{new_purchase_window.checksum_source}"
                end

                associated_purchase_window = new_purchase_window
              end

              new_vehicle_journey.purchase_windows << associated_purchase_window
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
              Rails.logger.info "failing vehicle journey:"
              Rails.logger.info "before:"
              Rails.logger.info vehicle_journey.inspect
              vehicle_journey.vehicle_journey_at_stops.each do |vjas|
                Rails.logger.info vjas.inspect
              end

              Rails.logger.info "after:"
              Rails.logger.info new_vehicle_journey.inspect
              new_vehicle_journey.vehicle_journey_at_stops.each do |vjas|
                Rails.logger.info vjas.inspect
              end

              raise "Checksum has changed for vehicle_journey #{vehicle_journey.id} :\n \"#{vehicle_journey.checksum_source}\" \n - \"#{vehicle_journey.checksum}\" \n => \n \"#{new_vehicle_journey.checksum_source}\"  \n - \"#{new_vehicle_journey.checksum}\""
            end

            new_vehicle_journey_ids[vehicle_journey.id] = new_vehicle_journey.id
          end
        end
      end
    end
  end

  def after_save_current
    referentials.each(&:merged!)
    new.update_stats!
    aggregate_if_urgent_offer
    HoleSentinel.new(workbench).watch!
  end

  def aggregate_if_urgent_offer
    workbench.workgroup.aggregate_urgent_data! if new&.contains_urgent_offer?
  end

  def save_model!(model)
    unless model.save
      Rails.logger.info "Merge ##{id}: Can't save #{model.class.name} : #{model.errors.inspect}"
      raise ActiveRecord::RecordNotSaved, "Invalid #{model.class.name} : #{model.errors.inspect}"
    end
    Rails.logger.debug { "Merge ##{id}: Created #{model.inspect}" }
  end

  def clean_scope
    scope = parent.merges
    if parent.locked_referential_to_aggregate_id.present?
      scope = scope.where("new_id IS NULL OR new_id != #{parent.locked_referential_to_aggregate_id}")
    end

    aggregated_referentials = parent.workgroup.aggregates.flat_map(&:referential_ids).compact.uniq
    if aggregated_referentials.present?
      scope = scope.where.not(new_id: aggregated_referentials)
    end

    scope
  end

  def concurent_operations
    parent.merges.where.not(id: self.id)
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
            created_at: metadata.created_at, # TODO check required dates
            flagged_urgent_at: metadata.urgent? ? Time.now : nil
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
