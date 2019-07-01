class ReferentialCopy
  extend Enumerize
  include ReferentialCopyHelpers
  include ProfilingSupport

  attr_accessor :source, :target, :status, :last_error

  enumerize :status, in: %w[new pending successful failed running], default: :new

  def initialize(opts={})
    @profiler = opts[:profiler]
    @source = opts[:source]
    @target = opts[:target]
    @opts = opts
    @lines = opts[:lines]
  end

  def logger
    @logger ||= Rails.logger
  end

  def skip_metadatas?
    @opts[:skip_metadatas]
  end

  def copy(raise_error: false)
    profile_tag :copy do
      ActiveRecord::Base.cache do
        Chouette::JourneyPattern.within_workgroup(workgroup) do
          Chouette::VehicleJourney.within_workgroup(workgroup) do
            copy_resource(:metadatas) unless skip_metadatas?
            copy_resource(:time_tables)
            copy_resource(:purchase_windows)
            source.switch do
              lines.includes(:footnotes, :routes).find_each do |line|
                @new_routes = nil
                copy_resource(:footnotes, line)
                copy_resource(:routes, line)
                copy_resource(:line_checksums, line)
              end
            end
            @status = :successful
          end
        end
      end
    end
  rescue SaveError => e
    logger.error e.message
    failed! e.message
    raise if raise_error
  end

  def copy!
    copy raise_error: true
  end

  def self.profile(source_id, target_id, profile_options={})
    copy = self.new(source: Referential.find(source_id), target: Referential.find(target_id))
    copy.profile = true
    copy.profile_options = profile_options

    copy.target.switch do
      [
        Chouette::VehicleJourneyAtStop,
        Chouette::VehicleJourney,
        Chouette::JourneyPattern,
        Chouette::TimeTable,
        Chouette::TimeTableDate,
        Chouette::TimeTablePeriod,
        Chouette::PurchaseWindow,
        Chouette::StopPoint,
        Chouette::Route,
        Chouette::Footnote
      ].each do |klass|
        klass.delete_all
      end
    end

    if profile_options[:operations]
      copy.profile_tag 'copy' do
        copy.source.switch do
          ActiveRecord::Base.cache do
            profile_options[:operations].each do |op|
              if op.is_a?(Array)
                copy.copy_resource op.first, *op[1..-1]
              else
                copy.copy_resource op
              end
            end
          end
        end
      end
    else
      copy.copy
    end

    copy
  end

  def copy_resource(resource_name, *params)
    profile_tag "copy_#{resource_name}" do
      send "copy_#{resource_name}", *params
    end
  end

  private

  def lines
    @lines ||= begin
      source.lines
    end
  end

  def workgroup
    @workgroup ||= target.workgroup
  end

  # METADATAS

  def copy_metadatas
    ReferentialMetadata.bulk_insert do |worker|
      source.metadatas.find_each do |metadata|
        candidate = target.metadatas.with_lines(metadata.line_ids).find { |m| m.periodes == metadata.periodes }
        candidate ||= target.metadatas.build(line_ids: metadata.line_ids, periodes: metadata.periodes)
        candidate.flagged_urgent_at = metadata.flagged_urgent_at if metadata.urgent?
        controlled_save! candidate, worker
      end
    end
  end

  # TIMETABLES

  def copy_time_tables
    table_ids = []
    Chouette::TimeTable.transaction do
      Chouette::ChecksumManager.no_updates do
        source.switch do
          Chouette::TimeTable.linked_to_lines(lines).distinct.find_each do |tt|
            attributes = clean_attributes_for_copy tt
            target.switch do
              new_tt = Chouette::TimeTable.new attributes
              controlled_save! new_tt
              table_ids << new_tt.id
              record_match(tt, new_tt)
              copy_bulk_collection tt.dates do |new_date_attributes|
                new_date_attributes[:time_table_id] = new_tt.id
              end
              copy_bulk_collection tt.periods do |new_period_attributes|
                new_period_attributes[:time_table_id] = new_tt.id
              end
              new_tt.reload.save_shortcuts
            end
          end
        end
      end
    end

    target.switch do
      update_checkum_in_batches target.time_tables.includes(:dates, :periods).where(id: table_ids)
    end
  end

  # PURCHASE WINDOWS

  def copy_purchase_windows
    Chouette::PurchaseWindow.transaction do
      source.switch do
        Chouette::PurchaseWindow.linked_to_lines(lines).distinct.find_each do |pw|
          attributes = clean_attributes_for_copy pw
          target.switch do
            new_pw = Chouette::PurchaseWindow.new attributes
            controlled_save! new_pw
            record_match(pw, new_pw)
          end
        end
      end
    end
  end

  # FOOTNOTES

  def copy_footnotes line
    line.footnotes.find_each do |footnote|
      copy_item_to_target_collection footnote, line.footnotes
    end
  end

  # ROUTES

  def copy_routes line
    Chouette::ChecksumManager.no_updates do
      line.routes.find_each &method(:copy_route)
    end
  end

  def copy_line_checksums(line)
    target.switch do
      update_checkum_in_batches Chouette::Route.where(id: @new_routes).select(:id, :name, :published_name, :wayback).includes(:stop_points, :routing_constraint_zones)
      update_checkum_in_batches target.vehicle_journey_at_stops.joins(vehicle_journey: :route).where(routes: {id: @new_routes}).select(:id, :departure_time, :arrival_time, :departure_day_offset, :arrival_day_offset)
      update_checkum_in_batches target.journey_patterns.where(route_id: @new_routes).select(:id, :custom_field_values, :name, :published_name, :registration_number, :costs).includes(:stop_points)
      update_checkum_in_batches target.vehicle_journeys.where(route_id: @new_routes).select(:id, :custom_field_values, :published_journey_name, :published_journey_identifier, :ignored_routing_contraint_zone_ids, :ignored_stop_area_routing_constraint_ids, :company_id, :line_notice_ids).includes(:company_light, :footnotes, :vehicle_journey_at_stops, :purchase_windows)
    end
  end

  def update_checkum_in_batches(collection)
    profile_tag 'update_checkum_in_batches' do
      Chouette::ChecksumManager.update_checkum_in_batches(collection, target)
    end
  end

  def copy_route route
    line = route.line
    attributes = clean_attributes_for_copy route
    opposite_route = route.opposite_route

    target.switch do
      new_route = line.routes.build attributes

      profile_tag 'stop_points' do
        copy_collection route, new_route, :stop_points
      end

      new_route.opposite_route_id = matching_id(opposite_route)

      controlled_save! new_route
      @new_routes ||= []
      @new_routes << new_route.id

      record_match(route, new_route)

      # we copy the journey_patterns
      profile_tag 'journey_patterns' do
        copy_collection route, new_route, :journey_patterns do |journey_pattern, new_journey_pattern|
          profile_tag 'stop_points' do
            new_journey_pattern.arrival_stop_point_id = nil
            new_journey_pattern.departure_stop_point_id = nil

            controlled_save! new_journey_pattern
            stop_point_ids = source.switch(verbose: false) do
              journey_pattern.stop_points.select(:id).map{|sp| matching_id(sp)}
            end

            if stop_point_ids.present?
              target.switch do
                Chouette::JourneyPatternsStopPoint.bulk_insert do |worker|
                  stop_point_ids.each do |id|
                    worker.add journey_pattern_id: new_journey_pattern.id, stop_point_id: id
                  end
                end

                new_journey_pattern.stop_points.reload
                new_journey_pattern.shortcuts_update_for_add(new_journey_pattern.stop_points.last)
              end
            end
          end

          profile_tag 'courses_stats' do
            sql = "INSERT INTO #{source.slug}.stat_journey_pattern_courses_by_dates (journey_pattern_id,route_id,line_id,date,count) "
            sql << "(SELECT '#{new_journey_pattern.id}','#{new_route.id}',line_id,date,count FROM #{target.slug}.stat_journey_pattern_courses_by_dates)"
            ActiveRecord::Base.connection.execute sql
          end

          profile_tag 'vehicle_journeys' do
            copy_collection journey_pattern, new_journey_pattern, :vehicle_journeys do |vj, new_vj|
              new_vj.route = new_route
              retrieve_collection_with_mapping vj, new_vj, Chouette::TimeTable, :time_tables
              retrieve_collection_with_mapping vj, new_vj, Chouette::PurchaseWindow, :purchase_windows
            end
          end

          profile_tag 'vehicle_journey_at_stops' do
            source.switch do
              journey_pattern.vehicle_journeys.find_each do |vj|
                copy_bulk_collection vj.vehicle_journey_at_stops.includes(:stop_point) do |new_vjas_attributes, vjas|
                  new_vjas_attributes[:vehicle_journey_id] = matching_id(vj)
                  new_vjas_attributes[:stop_point_id] = matching_id(vjas.stop_point)
                end
              end
            end
          end
          profile_tag 'update_checksum' do
            new_journey_pattern.vehicle_journeys.reload.each &:update_checksum!
          end
        end

        # we copy the routing_constraint_zones
        profile_tag 'routing_constraint_zones' do
          copy_collection route, new_route, :routing_constraint_zones do |rcz, new_rcz|
            new_rcz.stop_point_ids = []
            retrieve_collection_with_mapping rcz, new_rcz, new_route.stop_points, :stop_points
          end
        end
      end
    end
    clean_matches Chouette::StopPoint, Chouette::JourneyPattern, Chouette::VehicleJourney, Chouette::RoutingConstraintZone
  end
end
