module TransportModeEnumerations
  extend ActiveSupport::Concern

  included do |source|
    extend Enumerize
    enumerize :transport_mode, in: TransportModeEnumerations.transport_modes

    # Tip: Use `enumerize_transport_submode` in models which supports transport_submode
  end

  def transport_mode_and_submode_match
    return unless transport_mode.present?

    submodes = TransportModeEnumerations.full_transport_modes[transport_mode.to_sym]

    return if submodes.blank? && transport_submode.blank?
    return if submodes&.include?(transport_submode.presence&.to_sym)

    errors.add(:transport_mode, :submode_mismatch)
  end

  module ClassMethods
    def enumerize_transport_submode
      enumerize :transport_submode, in: TransportModeEnumerations.transport_submodes, default: "undefined"
    end

    def transport_modes
      TransportModeEnumerations.transport_modes
    end

    def sorted_transport_modes
      TransportModeEnumerations.sorted_transport_modes
    end

    def transport_submodes
      TransportModeEnumerations.transport_submodes
    end

    def formatted_submodes_for_transports(modes=nil)
      TransportModeEnumerations.formatted_submodes_for_transports(modes)
    end
  end

  class << self
    def transport_modes
      full_transport_modes.keys
    end

    def transport_submodes
      full_transport_modes.values.flatten.uniq
    end

    def full_transport_modes
      {
        metro: [
          :undefined,
          :metro,
          :tube,
          :urbanRailway
        ],
        funicular: [
          :undefined,
          :allFunicularServices,
          :streetCableCar,
          :funicular,
        ],
        trolleyBus: [
          :undefined
        ],
        tram: [
          :undefined,
          :cityTram,
          :localTram,
          :regionalTram,
          :shuttleTram,
          :sightseeingTram,
          :tramTrain
        ],
        rail: [
          :undefined,
          :carTransportRailService,
          :crossCountryRail,
          :highSpeedRail,
          :international,
          :interregionalRail,
          :local,
          :longDistance,
          :monorail,
          :nightTrain,
          :rackAndPinionRailway,
          :railShuttle,
          :regionalRail,
          :replacementRailService,
          :sleeperRailService,
          :specialTrain,
          :suburbanRailway,
          :touristRailway,
        ],
        coach: [
          :undefined,
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
          :undefined,
          :airportLinkBus,
          :demandAndResponseBus,
          :expressBus,
          :highFrequencyBus,
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
          :undefined,
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
          :undefined,
          :cableCar,
          :chairLift,
          :dragLift,
          :lift,
          :telecabinLink,
          :telecabin,
        ],
        air: [
          :undefined,
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
          :undefined,
          :allHireVehicles,
          :hireCar,
          :hireCycle,
          :hireMotorbike,
          :hireVan,
        ],
        taxi: [
          :undefined,
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

    alias_method :submodes_for_transports, :full_transport_modes

    def sorted_transport_modes
      transport_modes.sort_by do |m|
        I18n.t("enumerize.transport_mode.#{m}").parameterize
      end
    end

    def formatted_submodes_for_transports(modes=nil)
      modes ||= full_transport_modes
      modes.map do |t,s|
        {
          t => s.map do |k|
            [I18n.t("enumerize.transport_submode.#{ k.presence || 'undefined' }"), k]
          end.sort_by { |k| k.last ? k.first : "" }
        }
      end.reduce({}, :merge)
    end
  end
end
