class ShapeProvider < ApplicationModel
  include CodeSupport

  belongs_to :shape_referential, required: true
  belongs_to :workbench, required: true

  has_many :shapes, dependent: :delete_all
  has_many :point_of_interests, class_name: 'PointOfInterest::Base', dependent: :delete_all
  has_many :point_of_interest_categories, class_name: 'PointOfInterest::Category', dependent: :delete_all
  has_many :service_facility_sets, class_name: 'ServiceFacilitySet', dependent: :delete_all
  has_many :accessibility_assessments, class_name: 'AccessibilityAssessment', dependent: :delete_all

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
