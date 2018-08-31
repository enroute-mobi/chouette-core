class ReferentialAudit
  class Checksums < Base

    def message record
      "#{record.class.name} ##{record.id} has an inconsistent checksum"
    end

    def find_faulty
      faulty = []
      models = [
        Chouette::Footnote.select(:id, :checksum_source, :code, :label),
        Chouette::JourneyPattern.select(:id, :checksum_source, :custom_field_values, :name, :published_name, :registration_number, :costs).includes(:stop_points),
        Chouette::PurchaseWindow.select(:id, :checksum_source, :name, :color, :date_ranges),
        Chouette::Route.select(:id, :checksum_source, :name, :published_name, :wayback).includes(:stop_points, :routing_constraint_zones),
        Chouette::RoutingConstraintZone.select(:id, :checksum_source, :stop_point_ids),
        Chouette::TimeTable.select(:id, :checksum_source, :int_day_types).includes(:dates, :periods),
        Chouette::VehicleJourneyAtStop.select(:id, :checksum_source, :departure_time, :arrival_time, :departure_day_offset, :arrival_day_offset),
        Chouette::VehicleJourney.select(:id, :checksum_source, :custom_field_values, :published_journey_name, :published_journey_identifier, :ignored_routing_contraint_zone_ids, :company_id).includes(:company, :footnotes, :vehicle_journey_at_stops, :purchase_windows)
      ]
      models.each do |model|
        model.klass.cache do
          model.find_each do |k|
            k.set_current_checksum_source
            faulty << k if k.checksum_source_changed?
          end
        end
      end
      faulty
    end
  end
end
