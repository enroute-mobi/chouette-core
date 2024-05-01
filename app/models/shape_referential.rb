class ShapeReferential < ApplicationModel

  has_one :workgroup
  has_many :shape_providers, dependent: :destroy
  has_many :shapes, dependent: :delete_all
  has_many :point_of_interests, class_name: "PointOfInterest::Base", dependent: :delete_all
  has_many :point_of_interest_categories, class_name: "PointOfInterest::Category", dependent: :delete_all
  has_many :service_facility_sets, class_name: 'ServiceFacilitySet', dependent: :delete_all

  def name
    self.class.ts
  end

end
