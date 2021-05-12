module VehicleJourneyControl
  class TimeTable < ComplianceControl
    enumerize :criticity, in: %i(error), scope: true, default: :error

    def self.default_code; "3-VehicleJourney-4" end
  end
end
