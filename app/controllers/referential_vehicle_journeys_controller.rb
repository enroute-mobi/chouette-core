# frozen_string_literal: true

# Browse all VehicleJourneys of the Referential
class ReferentialVehicleJourneysController < ChouetteController
  include ReferentialSupport

  defaults :resource_class => Chouette::VehicleJourney, collection_name: :vehicle_journeys
  belongs_to :referential

  respond_to :html, only: :index

  def index
    index! do |format|
      format.html {
        @vehicle_journeys = decorate_collection(collection)
      }
    end
  end

  protected

  def scope
    parent.vehicle_journeys
  end

  def search
    @search ||= Search::VehicleJourney.new(scope, params, referential: referential)
  end
  delegate :collection, to: :search


  def decorate_collection(vehicle_journeys)
    VehicleJourneyDecorator.decorate(
      vehicle_journeys,
      context: {
        referential: referential
      }
    )
  end

end
