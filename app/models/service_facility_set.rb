class ServiceFacilitySet < ActiveRecord::Base
  include CodeSupport
  include ShapeReferentialSupport
  include NilIfBlank
  extend Enumerize

  has_array_of :vehicle_journeys, class_name: 'Chouette::VehicleJourney'

  validates :name, presence: true

  def candidate_categories
    Chouette::ServiceFacility.categories
  end

  def display_associated_services
    associated_services.map(&:human_name).join(', ')
  end

  def associated_services
    super.reject(&:blank?).map { |associated_service| Chouette::ServiceFacility.from(associated_service) }
  end
end