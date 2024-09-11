# frozen_string_literal: true

class RemoveWorkgroupsTransportModes < ActiveRecord::Migration[5.2]
  def up
    on_public_schema_only do
      change_table :workgroups do |t|
        t.remove :transport_modes
      end
    end
  end

  def down # rubocop:disable Metrics/MethodLength
    on_public_schema_only do
      change_table :workgroups do |t|
        # rubocop:disable Layout/LineLength
        t.jsonb :transport_modes, default: {
          'air' => %w[undefined airshipService domesticCharterFlight domesticFlight domesticScheduledFlight helicopterService intercontinentalCharterFlight intercontinentalFlight internationalCharterFlight internationalFlight roundTripCharterFlight schengenAreaFlight shortHaulInternationalFlight shuttleFlight sightseeingFlight],
          'bus' => %w[undefined airportLinkBus demandAndResponseBus expressBus highFrequencyBus localBus mobilityBusForRegisteredDisabled mobilityBus nightBus postBus railReplacementBus regionalBus schoolAndPublicServiceBus schoolBus shuttleBus sightseeingBus specialNeedsBus],
          'rail' => %w[undefined carTransportRailService crossCountryRail highSpeedRail international interregionalRail local longDistance nightTrain rackAndPinionRailway railShuttle regionalRail replacementRailService sleeperRailService specialTrain suburbanRailway touristRailway],
          'taxi' => %w[undefined allTaxiServices bikeTaxi blackCab communalTaxi miniCab railTaxi waterTaxi],
          'tram' => %w[undefined cityTram localTram regionalTram shuttleTram sightseeingTram tramTrain],
          'coach' => %w[undefined commuterCoach internationalCoach nationalCoach regionalCoach shuttleCoach sightseeingCoach specialCoach touristCoach],
          'metro' => %w[undefined metro tube urbanRailway],
          'water' => %w[undefined internationalCarFerry nationalCarFerry regionalCarFerry localCarFerry internationalPassengerFerry nationalPassengerFerry regionalPassengerFerry localPassengerFerry postBoat trainFerry roadFerryLink airportBoatLink highSpeedVehicleService highSpeedPassengerService sightseeingService schoolBoat cableFerry riverBus scheduledFerry shuttleFerryService],
          'hireCar' => %w[undefined allHireVehicles hireCar hireCycle hireMotorbike hireVan],
          'funicular' => %w[undefined allFunicularServices funicular],
          'telecabin' => %w[undefined cableCar chairLift dragLift lift telecabinLink telecabin]
        }
        # rubocop:enable Layout/LineLength
      end
    end
  end
end
