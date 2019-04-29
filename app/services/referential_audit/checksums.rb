class ReferentialAudit
  class Checksums < Base

    def message(record, output: :console)
      "#{record[:class_name]} ##{record[:id]} has an inconsistent checksum"
    end

    def find_faulty
      faulty = []
      models = [
        Chouette::Footnote.select(:id, :checksum_source, :checksum, :code, :label),
        Chouette::JourneyPattern.select(:id, :checksum_source, :checksum, :custom_field_values, :name, :published_name, :registration_number, :costs, :route_id).includes(:stop_point_lights),
        Chouette::PurchaseWindow.select(:id, :checksum_source, :checksum, :name, :color, :date_ranges),
        Chouette::Route.select(:id, :checksum_source, :checksum, :name, :published_name, :wayback).includes(:stop_points, :routing_constraint_zones),
        Chouette::RoutingConstraintZone.select(:id, :checksum_source, :checksum, :stop_point_ids),
        Chouette::TimeTable.select(:id, :checksum_source, :checksum, :int_day_types).includes(:dates, :periods),
        Chouette::VehicleJourneyAtStop.select(:id, :checksum_source, :checksum, :departure_time, :arrival_time, :departure_day_offset, :arrival_day_offset),
        Chouette::VehicleJourney.select(:id, :checksum_source, :checksum, :custom_field_values, :published_journey_name, :published_journey_identifier, :ignored_routing_contraint_zone_ids, :ignored_stop_area_routing_constraint_ids, :company_id, :line_notice_ids).includes(:company_light, :footnotes, :vehicle_journey_at_stops, :purchase_windows)
      ]
      models.each do |model|
        Chouette::ActiveRecord.within_workgroup(@referential.workgroup) do
          profile_tag model.klass.name do
            model.klass.cache do
              model.find_each do |k|
                profile_tag :checksum, silent: true do
                  k.set_current_checksum_source(db_lookup: false)
                  if k.checksum_source_changed?
                    profile_tag :faulty, silent: true do
                      faulty << { class_name: k.class.name, id: k.id }
                    end
                    next
                  end
                  k.update_checksum(force: true, silent: true)
                  if k.checksum_changed?
                    profile_tag :faulty, silent: true do
                      faulty << { class_name: k.class.name, id: k.id }
                    end
                  end
                end
              end
            end
          end
        end
      end
      faulty
    end
  end
end
