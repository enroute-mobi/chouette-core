module VehicleJourneyControl
  class VehicleJourneyAtStops < ComplianceControl
    enumerize :criticity, in: %i(error), scope: true, default: :error

    def self.default_code; "3-VehicleJourney-5" end
  end
end
