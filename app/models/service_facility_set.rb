class ServiceFacilitySet < ActiveRecord::Base
  include CodeSupport
  include ShapeReferentialSupport
  include NilIfBlank
  extend Enumerize

  belongs_to_array_in_many :vehicle_journeys, class_name: 'Chouette::VehicleJourney', array_name: :service_facility_sets

  validates :name, :associated_services, presence: true

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