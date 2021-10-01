class ReferentialAudit
  class Checksums < Base

    def message(record, output: :console)
      "#{record.class.name} ##{record.id} has an inconsistent checksum"
    end

    def find_faulty
      faulty = []
      models = [
        Chouette::Footnote.select(:id, :checksum_source, :checksum, :code, :label),
        Chouette::JourneyPattern.select(:id, :checksum_source, :checksum, :custom_field_values, :name, :published_name, :registration_number, :costs, :route_id, :shape_id).includes(:stop_points),
        Chouette::Route.select(:id, :checksum_source, :checksum, :name, :published_name, :wayback).includes(:stop_points, :routing_constraint_zones),
        Chouette::RoutingConstraintZone.select(:id, :checksum_source, :checksum, :stop_point_ids),
        Chouette::TimeTable.select(:id, :checksum_source, :checksum, :int_day_types).includes(:dates, :periods),
        Chouette::VehicleJourneyAtStop.select(:id, :checksum_source, :checksum, :departure_time, :arrival_time, :departure_day_offset, :arrival_day_offset, :stop_area_id),
        Chouette::VehicleJourney.select(:id, :checksum_source, :checksum, :custom_field_values, :published_journey_name, :published_journey_identifier, :ignored_routing_contraint_zone_ids, :ignored_stop_area_routing_constraint_ids, :company_id, :line_notice_ids).includes(:company_light, :footnotes, :vehicle_journey_at_stops)
      ]
      if @referential.referential_suite_id.present?
        models.each do |model|
          lookup = Proc.new {
            model.find_each do |k|
              k.set_current_checksum_source(db_lookup: false)
              k.update_checksum(force: true, silent: true)
              faulty << k if k.checksum_source_changed?
              faulty << k if k.checksum_changed?
            end
          }
          model.klass.cache do
            CustomFieldsSupport.within_workgroup(@referential.workgroup, &lookup)
          end
        end
      end
      faulty
    end
  end
end
