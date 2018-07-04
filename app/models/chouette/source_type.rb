module Chouette
  class SourceType < TextAndNumericalType
    DEFINITIONS = [
      ["public_and_private_utilities", 0],
      ["road_authorities", 1],
      ["transit_operator", 2],
      ["public_transport", 3],
      ["passenger_transport_coordinating_authority", 4],
      ["travel_information_service_provider", 5],
      ["travel_agency", 6],
      ["individual_subject_of_travel_itinerary", 7],
      ["other_information", 8],
    ].freeze
  end
end
