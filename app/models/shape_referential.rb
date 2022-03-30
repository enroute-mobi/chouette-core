class ShapeReferential < ApplicationModel

  has_one :workgroup
  has_many :shape_providers
  has_many :shapes
  has_many :point_of_interests, class_name: "PointOfInterest::Base"
  has_many :point_of_interest_categories, class_name: "PointOfInterest::Category"

  def name
    self.class.ts
  end

end
