# frozen_string_literal: true

module Policy
  class ShapeProvider < Base
    authorize_by Strategy::Permission

    protected

    def _create?(resource_class)
      [
        ::PointOfInterest::Category,
        ::PointOfInterest::Base,
        ::ServiceFacilitySet,
        ::AccessibilityAssessment
      ].include?(resource_class)
    end
  end
end
