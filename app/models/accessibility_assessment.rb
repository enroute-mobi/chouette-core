class AccessibilityAssessment < ApplicationModel
  include CodeSupport
  include ShapeReferentialSupport
  include NilIfBlank
  extend Enumerize

  validates :name, presence: true

  enumerize :mobility_impaired_accessibility, in: %i[unknown yes no partial], default: :unknown
  enumerize :wheelchair_accessibility, in: %i[unknown yes no partial], default: :unknown
  enumerize :step_free_accessibility, in: %i[unknown yes no partial], default: :unknown
  enumerize :escalator_free_accessibility, in: %i[unknown yes no partial], default: :unknown
  enumerize :lift_free_accessibility, in: %i[unknown yes no partial], default: :unknown
  enumerize :audible_signals_availability, in: %i[unknown yes no partial], default: :unknown
  enumerize :visual_signs_availability, in: %i[unknown yes no partial], default: :unknown
end
