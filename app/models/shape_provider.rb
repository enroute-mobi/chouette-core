class ShapeProvider < ApplicationModel
  include CodeSupport

  belongs_to :shape_referential # TODO: CHOUETTE-3247 optional: true?
  belongs_to :workbench # TODO: CHOUETTE-3247 optional: true?

  has_many :shapes
  has_many :point_of_interests, class_name: 'PointOfInterest::Base'
  has_many :point_of_interest_categories, class_name: 'PointOfInterest::Category'
  has_many :service_facility_sets, class_name: 'ServiceFacilitySet'
  has_many :accessibility_assessments, class_name: 'AccessibilityAssessment'
  has_many :equipements, class_name: 'Equipement'

  validates :short_name, presence: true

  before_validation :define_shape_referential, on: :create

  delegate :workgroup, to: :workbench, allow_nil: true

  def name
    short_name
  end

  private

  def define_shape_referential
    self.shape_referential ||= workgroup&.shape_referential
  end
end
