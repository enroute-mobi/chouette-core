class Merge < ApplicationModel
  include OperationSupport
  include NotifiableSupport

  belongs_to :workbench

  validates :workbench, presence: true

  has_many :compliance_check_sets, -> { where(parent_type: "Merge") }, foreign_key: :parent_id, dependent: :destroy

  delegate :output, to: :workbench

  delegate :workgroup, to: :workbench

  after_commit :merge, :on => :create, unless: :profile?

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

  def self.profile(source=nil, opts={})
    w = Workbench.first
    source ||= w.referentials.mergeable.last
    merge = self.new referentials: [source], workbench: w
    merge.profile = true
    merge.profile_options = opts
    merge.save!
    Referential.where(slug: "output_#{w.id}_#{merge.created_at.to_i}").destroy_all

    merge.merge!
    merge
  end

  def merge
    # Step 1 : Before
    update_column :started_at, Time.now
    update_column :status, :running

    referentials.each(&:pending!)

    if before_merge_compliance_control_sets.present?
      create_before_merge_compliance_check_sets
    else
      MergeWorker.perform_async_or_fail(self)
    end
  end

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
    profile_tag 'merge' do
      prepare_new

      referentials.each do |referential|
        merge_referential referential
      end

      clean_new

      if after_merge_compliance_control_sets.present?
        create_after_merge_compliance_check_sets
      else
        save_current
      end
    end
  rescue => e
    Rails.logger.error "Merge ##{id} failed: #{e} #{e.backtrace.join("\n")}"
    failed!
    raise e# if Rails.env.test?
  end

  def prepare_new
    profile_tag 'prepare_new' do
      clone_metadata = false
      new =
        if workbench.output.current && profile? && !profile_options[:new_output]
          Rails.logger.debug "Merge ##{id}: Clone current output"
          clone_metadata = true
          Referential.new_from(workbench.output.current, workbench, true).tap do |clone|
            clone.inline_clone = true
          end
        else
          if workbench.merges.successful.count > 0 && profile? && !profile_options[:new_output]
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

      if clone_metadata
        ReferentialMetadata.bulk_insert_from workbench.output.current.metadatas, workbench, new
      end
      new.metadatas.reload
      new.flag_not_urgent!
      new.pending!

      output.update new: new
      update new: new
    end
  end

  def clean_new
    profile_operation 'clean_new' do
      CleanUp.new(referential: new, clean_methods: [:clean_irrelevant_data, :clean_unassociated_calendars]).clean
    end
  end

  def merge_referential_metadata(referential)
    profile_operation 'merge_referential_metadata' do
      metadata_merger = MetadatasMerger.new new, referential
      metadata_merger.merge

      new.metadatas.delete metadata_merger.empty_metadatas

      new.save!
    end
  end

  def merge_referential(referential)
    @altered_lines = []
    profile_operation 'merge_referential' do
      ActiveRecord::Base.cache do
        Rails.logger.debug "Merge ##{id}: Merge #{referential.slug}"

        merge_referential_metadata(referential)

        @line_periods = LinePeriods.from_metadatas(referential.metadatas)

        new.metadatas.reload

        profile_tag 'clean_timetables' do
          new.switch do
            @line_periods.each do |line_id, periods|
              Rails.logger.debug "Merge ##{id}: Clean data for #{line_id} #{periods.inspect}"
              @altered_lines << line_id
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
        end

        merge_footnotes referential

        page = 0
        referential_routes = routes_batch(page, referential)
        @new_vehicle_journey_ids = {}

        while referential_routes.present?
          profile_tag 'routes_batch' do
            @referential_routes_lines = nil
            @referential_routes_checksums = nil
            @referential_journey_patterns_checksums = nil
            @referential_routing_constraint_zones_new_ids = nil

            Chouette::ActiveRecord.within_workgroup workgroup do
              merge_routes referential, referential_routes
              merge_routes_journey_patterns referential, referential_routes
              merge_routes_vehicle_journeys referential, referential_routes
            end
            page += 1
            referential_routes = routes_batch(page, referential)
          end
        end
        merge_time_tables referential
      end
    end
  end

  def routes_batch(page, referential)
    page_size = 10
    referential.switch do
      referential.routes.offset(page*page_size).limit(page_size).all.to_a
    end
  end

  def merge_routes(referential, referential_routes)
    profile_operation 'merge_routes' do
      @referential_routes_checksums = Hash[referential_routes.map { |r| [ r.id, r.checksum ] }]
      @referential_routes_lines = Hash[referential_routes.map { |r| [ r.id, r.line_id ] }]

      referential_stop_points = referential.switch do
        referential.stop_points.where(route_id: referential_routes.map(&:id)).all.to_a
      end

      referential_stop_points_by_route = referential_stop_points.group_by(&:route_id)

      referential_routing_constraint_zones = referential.switch do
        referential.routing_constraint_zones.where(route_id: referential_routes.map(&:id)).each_with_object(Hash.new { |h,k| h[k] = {}}) do |routing_constraint_zone, hash|
          hash[routing_constraint_zone.route_id][routing_constraint_zone.checksum] = routing_constraint_zone
        end
      end

      referential_route_opposite_route_ids = referential.switch do
        Hash[referential.routes.where('opposite_route_id is not null').pluck(:id, :opposite_route_id)]
      end

      @referential_routing_constraint_zones_new_ids = {}

      new.switch do
        route_ids_mapping = {}
        route_objectids = referential_routes.map(&:objectid)
        route_objectids = Chouette::Route.where(objectid: route_objectids).group(:objectid).count

        referential_routes.each_slice(10) do |routes|
          Chouette::Route.transaction do
            routes.each do |route|
              existing_route = new.routes.find_by line_id: route.line_id, checksum: route.checksum
              if existing_route
                route_ids_mapping[route.id] = existing_route.id
                existing_route.merge_metadata_from route
              else
                objectid = route_objectids[route.objectid] ? nil : route.objectid
                attributes = route.attributes.merge(
                  id: nil,
                  objectid: objectid,
                  # line_id is the same
                  # all other primary must be changed
                  opposite_route_id: nil # merged after
                )
                new_route = new.routes.build attributes

                # We need to create the route to known its primary key
                Chouette::ChecksumManager.no_updates do
                  save_model! new_route
                end

                route_stop_points = referential_stop_points_by_route[route.id] || []

                profile_tag 'route_stop_points' do
                  objectids = route_stop_points.map(&:objectid)
                  objectids = Chouette::StopPoint.where(objectid: objectids).group(:objectid).count

                  # Stop Points
                  Chouette::StopPoint.bulk_insert do |worker|
                    route_stop_points.sort_by(&:position).each do |stop_point|
                      objectid = objectids[stop_point.objectid] ? nil : stop_point.objectid
                      worker.add stop_point.attributes.merge(objectid: objectid, route_id: new_route.id)
                    end
                  end
                end

                new_route.stop_points.reload

                route_ids_mapping[route.id] = new_route.id

                old_stop_point_ids = route_stop_points.sort_by(&:position).map(&:id)
                new_stop_point_ids = new_route.stop_points.sort_by(&:position).map(&:id)

                stop_point_ids_mapping = Hash[[old_stop_point_ids, new_stop_point_ids].transpose]

                # RoutingConstraintZones
                routing_constraint_zones = referential_routing_constraint_zones[route.id]

                profile_tag 'routing_constraint_zones' do
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
                end

                Chouette::Route.skipping_objectid_uniqueness do
                  save_model! new_route
                end

                if new_route.checksum != route.checksum
                  raise "Checksum has changed: \"#{route.checksum}\", \"#{route.checksum_source}\" -> \"#{new_route.checksum}\", \"#{new_route.checksum_source}\""
                end

                if new_route.routing_constraint_zones.map(&:checksum).sort != routing_constraint_zones.keys.sort
                  raise "Checksum has changed in RoutingConstraintZones: \"#{new_route.routing_constraint_zones.map(&:checksum).sort}\" -> \"#{route.routing_constraint_zones.map(&:checksum).sort}\""
                end

                new_route.routing_constraint_zones.each do |new_routing_constraint_zone|
                  routing_constraint_zone = routing_constraint_zones[new_routing_constraint_zone.checksum]
                  if routing_constraint_zone
                    @referential_routing_constraint_zones_new_ids[routing_constraint_zone.id] = new_routing_constraint_zone.id
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
              end
              Rails.logger.warn "Merge ##{id}: Can't merge opposite route for Route #{route_id}" unless new_route
            end
          end
        end
      end
    end
  end

  def merge_routes_journey_patterns(referential, referential_routes)
    scoped_journey_patterns = referential.journey_patterns.where(route_id: referential_routes.map(&:id))

    referential_journey_patterns, referential_journey_patterns_stop_areas_objectids = referential.switch do
      journey_patterns = referential.journey_patterns

      journey_patterns_stop_areas_objectids = {}
      journey_patterns.includes(stop_points: :stop_area).find_each do |journey_pattern|
        journey_patterns_stop_areas_objectids[journey_pattern.id] = journey_pattern.stop_points.map { |sp| [sp.position, sp.stop_area.raw_objectid]}
      end

      [journey_patterns.to_a, journey_patterns_stop_areas_objectids]
    end

    referential_journey_patterns_checksums = {}
    referential_journey_patterns.each { |j| referential_journey_patterns_checksums[j.id] = j.checksum }

      @referential_journey_patterns_checksums = Hash[referential_journey_patterns.map { |j| [ j.id, j.checksum ] }]

      new.switch do
        referential_journey_patterns.each_slice(20) do |journey_patterns|
          Chouette::JourneyPattern.transaction do
            journey_patterns.each do |journey_pattern|
              # find parent route by checksum
              profile_tag 'journey_pattern' do
                associated_line_id = @referential_routes_lines[journey_pattern.route_id]
                associated_route_checksum = @referential_routes_checksums[journey_pattern.route_id]
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

                  profile_tag 'stop_points' do
                    stop_areas_objectids = referential_journey_patterns_stop_areas_objectids[journey_pattern.id]
                    stop_areas_objectids = stop_areas_objectids.map {|position, objectid| "('#{objectid}', #{position})"}
                    stop_points = existing_associated_route.stop_points.joins(:stop_area).where("(stop_areas.objectid, stop_points.position) IN (#{stop_areas_objectids.join(',')})")

                    if stop_points.count != stop_areas_objectids.count
                      raise "Can't find StopPoints for #{stop_areas_objectids} : #{stop_points.inspect} #{existing_associated_route.stop_points.inspect}"
                    end

                    attributes.merge!(stop_points: stop_points)
                  end

                  new_journey_pattern = new.journey_patterns.build attributes

                  save_model! new_journey_pattern

                  if new_journey_pattern.checksum != journey_pattern.checksum
                    raise "Checksum has changed for #{journey_pattern.inspect} (to #{new_journey_pattern.inspect}): \"#{journey_pattern.checksum_source}\" -> \"#{new_journey_pattern.checksum_source}\""
                  end
                end
              end
            end
          end
        end
      end
    end
  end

  def merge_footnotes(referential)
    # Footnotes
    profile_operation 'merge_footnotes' do
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
              raise "Checksum has changed: \"#{footnote.checksum}\", \"#{footnote.checksum_source}\" -> \"#{new_footnote.checksum}\", \"#{new_footnote.checksum_source}\""
            end
          end
        end
      end
    end
  end

  def merge_routes_vehicle_journeys(referential, referential_routes)
    # Vehicle Journeys
    profile_operation 'merge_routes_vehicle_journeys' do
      referential.switch do
        referential.vehicle_journeys.where(route_id: referential_routes.map(&:id)).includes(:vehicle_journey_at_stops, :purchase_windows, :footnotes).find_in_batches(batch_size: vehicle_journeys_batch_size) do |referential_vehicle_journeys|
          merge_vehicle_journeys referential, referential_vehicle_journeys
        end
      end
    end
  end

  def merge_time_tables(referential)
    # Time Tables

    referential_time_tables_by_id, referential_time_tables_with_lines = referential.switch do
      time_tables_by_id = {}
      referential.time_tables.includes(:dates, :periods).find_each do |t|
        time_tables_by_id[t.id] = t
      end

    profile_tag 'time_tables' do
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

                candidate_time_table.intersect_periods! @line_periods.periods(line_id)
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

                  new_vehicle_journey_id = @new_vehicle_journey_ids[properties[:vehicle_journey_id]]
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

  def merge_vehicle_journeys(referential, referential_vehicle_journeys)
    vehicle_journey_ids = referential_vehicle_journeys.map(&:id)

    referential_purchase_windows_by_checksum = {}
    referential_vehicle_journey_purchase_window_checksums = Hash.new { |h,k| h[k] = [] }
    referential_vehicle_journey_footnote_checksums = {}

    referential.switch do
      referential_vehicle_journeys.each do |vehicle_journey|
        vehicle_journey.purchase_windows.each do |purchase_window|
          referential_purchase_windows_by_checksum[purchase_window.checksum] = purchase_window
          referential_vehicle_journey_purchase_window_checksums[vehicle_journey.id] << purchase_window.checksum
        end
      end
      referential_vehicle_journey_footnote_checksums = Chouette::Footnote.joins(:vehicle_journeys).group('vehicle_journeys.id').select('vehicle_journeys.id, array_agg(footnotes.checksum) as checksums').map(&:attributes).map(&:values).to_h
    end

    new.switch do
      Chouette::VehicleJourney.transaction do
        referential_vehicle_journeys.each do |vehicle_journey|
          profile_tag 'vehicle_journey' do
            # find parent journey pattern by checksum
            associated_line_id = @referential_routes_lines[vehicle_journey.route_id]
            associated_route_checksum = @referential_routes_checksums[vehicle_journey.route_id]
            associated_journey_pattern_checksum = @referential_journey_patterns_checksums[vehicle_journey.journey_pattern_id]

            existing_associated_route = new.routes.find_by checksum: associated_route_checksum, line_id: associated_line_id
            existing_associated_journey_pattern = existing_associated_route.journey_patterns.find_by checksum: associated_journey_pattern_checksum

            existing_vehicle_journey = new.vehicle_journeys.find_by journey_pattern_id: existing_associated_journey_pattern.id, checksum: vehicle_journey.checksum

            if existing_vehicle_journey
              existing_vehicle_journey.merge_metadata_from vehicle_journey
              @new_vehicle_journey_ids[vehicle_journey.id] = existing_vehicle_journey.id
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

              Chouette::ChecksumManager.no_updates do
                save_model! new_vehicle_journey
              end

              # Create VehicleJourneyAtStops
              profile_tag 'vehicle_journey_at_stops' do
                stop_point_ids = existing_associated_journey_pattern.stop_points.pluck(:id)
                Chouette::VehicleJourneyAtStop.bulk_insert do |worker|
                  vehicle_journey.vehicle_journey_at_stops.each_with_index do |vehicle_journey_at_stop, index|
                    worker.add vehicle_journey_at_stop.attributes.merge(
                      vehicle_journey_id: new_vehicle_journey.id,
                      stop_point_id: stop_point_ids[index],
                    )
                  end
                end
              end

              new_vehicle_journey.vehicle_journey_at_stops.reload

              # Associate (and create if needed) PurchaseWindows
              profile_tag 'purchase_windows' do
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
                      raise "Checksum has changed: #{purchase_window.checksum_source} #{new_purchase_window.checksum_source}"
                    end

                    associated_purchase_window = new_purchase_window
                  end

                  new_vehicle_journey.purchase_windows << associated_purchase_window
                end
              end

              # Associate Footnotes

              if referential_vehicle_journey_footnote_checksums[vehicle_journey.id]
                referential_vehicle_journey_footnote_checksums[vehicle_journey.id].each do |footnote_checksum|
                  associated_footnote = new.footnotes.find_by(line_id: associated_line_id, checksum: footnote_checksum)
                  new_vehicle_journey.footnotes << associated_footnote
                end
              end

              # Rewrite ignored_routing_contraint_zone_ids
              new_vehicle_journey.ignored_routing_contraint_zone_ids = @referential_routing_constraint_zones_new_ids.values_at(*vehicle_journey.ignored_routing_contraint_zone_ids).compact
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

                raise "Checksum has changed: \"#{vehicle_journey.checksum_source}\" \"#{vehicle_journey.checksum}\" -> \"#{new_vehicle_journey.checksum_source}\" \"#{new_vehicle_journey.checksum}\""
              end

              @new_vehicle_journey_ids[vehicle_journey.id] = new_vehicle_journey.id
            end
          end
        end
      end
    end
  end

  def after_save_current
    referentials.each(&:merged!)
    lines = new.switch { new.lines.where(id: @altered_lines) }
    new.update_stats!(lines: lines)

    return if profile?
    aggregate_if_urgent_offer
    HoleSentinel.new(workbench).watch!
  end

  def aggregate_if_urgent_offer
    workbench.workgroup.aggregate_urgent_data! if new&.contains_urgent_offer?
  end

  def save_model!(model)
    profile_tag "save_model_#{model.class.name}" do
      unless model.save
        Rails.logger.info "Merge ##{id}: Can't save #{model.class.name} : #{model.errors.inspect}"
        raise ActiveRecord::RecordNotSaved, "Invalid #{model.class.name} : #{model.errors.inspect}"
      end
      Rails.logger.debug { "Merge ##{id}: Created #{model.inspect}" }
    end
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

  class MetadatasMerger
    attr_reader :merge_metadatas, :referential
    def initialize(final_referential, referential)
      @final_referential = final_referential
      @merge_metadatas = final_referential.metadatas
      @referential = referential
    end

    delegate :metadatas, to: :referential, prefix: :referential

    def merge
      ReferentialMetadata.bulk_insert do |worker|
        referential_metadatas.each do |metadata|
          merge_one metadata, worker
        end
      end
    end

    def merged_line_metadatas(line_id)
      merge_metadatas.select do |m|
        m.line_ids.include? line_id
      end
    end

    def merge_one(metadata, worker)
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
            flagged_urgent_at: metadata.urgent? ? Time.now : nil,
            referential_id: @final_referential.id
          }

          # line_metadatas should not contain conflicted metadatas
          worker.add attributes
        end
      end
    end

    def empty_metadatas
      merge_metadatas.select { |m| m.periodes.empty? }
    end
  end
end
