# frozen_string_literal: true

# Browse all VehicleJourneys of the Referential
class ReferentialVehicleJourneysController < ChouetteController
  include ReferentialSupport

  defaults :resource_class => Chouette::VehicleJourney, collection_name: :vehicle_journeys
  belongs_to :referential

  respond_to :html, only: :index

  def index
    index! do
      @vehicle_journeys_for_paginate = search.without_order.search(scope)
      @enable_complex_sort = @vehicle_journeys_for_paginate.count < 50000
      
      search_scope = scope
      search_scope = scope.with_departure_arrival_second_offsets if @enable_complex_sort
      
      @vehicle_journeys = decorate_collection(search.search(search_scope))
    end
  end

  protected

  def scope
    parent.vehicle_journeys
  end

  def search
    @search ||= Search::VehicleJourney.from_params(params, referential: referential)
  end

  def decorate_collection(vehicle_journeys)
    VehicleJourneyDecorator.decorate(
      vehicle_journeys,
      context: {
        referential: referential
      }
    )
  end
end
