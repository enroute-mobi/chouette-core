class ShapeReferential < ApplicationModel

  has_one :workgroup
  has_many :shape_providers
  has_many :shapes
  has_many :point_of_interests, class_name: "PointOfInterest::Base"
  has_many :point_of_interest_categories, class_name: "PointOfInterest::Category"
  has_many :service_facility_sets, class_name: 'ServiceFacilitySet'

  def name
    self.class.ts
  end

end
