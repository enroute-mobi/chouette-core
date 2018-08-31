class ReferentialAudit
  class Checksums < Base

    def message record
      "#{record.class.name} ##{record.id} has an inconsistent checksum"
    end

    def find_faulty
      faulty = []
      models = [
        Chouette::Footnote,
        Chouette::JourneyPattern,
        Chouette::PurchaseWindow,
        Chouette::Route,
        Chouette::RoutingConstraintZone,
        Chouette::TimeTable,
        Chouette::VehicleJourneyAtStop,
        Chouette::VehicleJourney
      ]
      models.each do |model|
        model.cache do
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
