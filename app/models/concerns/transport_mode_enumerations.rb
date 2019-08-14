module TransportModeEnumerations
  extend ActiveSupport::Concern

  included do
    extend Enumerize
    enumerize :transport_mode, in: TransportModeEnumerations.transport_modes
  end

  module ClassMethods
    def transport_modes
      NetexTransportModeEnumerations.transport_modes
    end

    def sorted_transport_modes
      NetexTransportModeEnumerations.sorted_transport_modes
    end
  end

  class << self
    def transport_modes
      full_transport_modes.keys
    end

    def full_transport_modes
      {
        metro: [
          :metro,
          :tube,
          :urbanRailway
        ],
        funicular: [
          :allFunicularServices,
          :funicular,
        ],
        tram: [
          :cityTram,
          :localTram,
          :regionalTram,
          :shuttleTram,
          :sightseeingTram,
          :tramTrain
        ],
        rail: [
          :carTransportRailService,
          :crossCountryRail,
          :highSpeedRail,
          :international,
          :interregionalRail,
          :local,
          :longDistance,
          :nightTrain,
          :rackAndPinionRailway,
          :railShuttle,
          :replacementRailService,
          :sleeperRailService,
          :specialTrain,
          :suburbanRailway,
          :touristRailway,
        ],
        coach: [
          :commuterCoach,
          :internationalCoach,
          :nationalCoach,
          :regionalCoach,
          :shuttleCoach,
          :sightseeingCoach,
          :specialCoach,
          :touristCoach,
        ],
        bus: [
          :airportLinkBus,
          :demandAndResponseBus,
          :espressBus,
          :localBus,
          :mobilityBusForRegisteredDisabled,
          :mobilityBus,
          :nightBus,
          :postBus,
          :railReplacementBus,
          :regionalBus,
          :schoolAndPublicServiceBus,
          :schoolBus,
          :shuttleBus,
          :sightseeingBus,
          :specialNeedsBus,
        ],
        water: [
          :internationalCarFerry,
          :nationalCarFerry,
          :regionalCarFerry,
          :localCarFerry,
          :internationalPassengerFerry,
          :nationalPassengerFerry,
          :regionalPassengerFerry,
          :localPassengerFerry,
          :postBoat,
          :trainFerry,
          :roadFerryLink,
          :airportBoatLink,
          :highSpeedVehicleService,
          :highSpeedPassengerService,
          :sightseeingService,
          :schoolBoat,
          :cableFerry,
          :riverBus,
          :scheduledFerry,
          :shuttleFerryService
        ],
        telecabin: [
          :cableCar,
          :chairLift,
          :dragLift,
          :lift,
          :telecabinLink,
          :telecabin,
        ],
        air: [
          :airshipService,
          :domesticCharterFlight,
          :domesticFlight,
          :domesticScheduledFlight,
          :helicopterService,
          :intercontinentalCharterFlight,
          :intercontinentalFlight,
          :internationalCharterFlight,
          :internationalFlight,
          :roundTripCharterFlight,
          :schengenAreaFlight,
          :shortHaulInternationalFlight,
          :shuttleFlight,
          :sightseeingFlight,
        ],
        hireCar: [
          :allHireVehicles,
          :hireCar,
          :hireCycle,
          :hireMotorbike,
          :hireVan,
        ],
        taxi: [
          :allTaxiServices,
          :bikeTaxi,
          :blackCab,
          :communalTaxi,
          :miniCab,
          :railTaxi,
          :waterTaxi,
        ]
      }
    end

    def sorted_transport_modes
      transport_modes.sort_by do |m|
        I18n.t("enumerize.transport_mode.#{m}").parameterize
      end
    end
  end
end
