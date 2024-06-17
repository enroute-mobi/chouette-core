# frozen_string_literal: true

class ShapeReferential < ApplicationModel
  has_one :workgroup
  has_many :shape_providers, dependent: :destroy
  has_many :shapes, dependent: :destroy
  has_many :point_of_interests, class_name: 'PointOfInterest::Base', dependent: :destroy
  has_many :point_of_interest_categories, class_name: 'PointOfInterest::Category', dependent: :destroy
  has_many :service_facility_sets, class_name: 'ServiceFacilitySet', dependent: :destroy
  has_many :accessibility_assessments, class_name: 'AccessibilityAssessment', dependent: :destroy

  def name
    self.class.ts
  end
end
