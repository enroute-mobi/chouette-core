class AccessibilityAssessment < ActiveRecord::Base
  include CodeSupport
  extend Enumerize

  belongs_to :referential, required: true

  validates :name, presence: true

  delegate :workbench, to: :referential

  enumerize :mobility_impaired_accessibility, in: %i[unknown yes no partial], default: :unknown
  enumerize :wheelchair_accessibility, in: %i[unknown yes no partial], default: :unknown
  enumerize :step_free_accessibility, in: %i[unknown yes no partial], default: :unknown
  enumerize :escalator_free_accessibility, in: %i[unknown yes no partial], default: :unknown
  enumerize :lift_free_accessibility, in: %i[unknown yes no partial], default: :unknown
  enumerize :audible_signals_availability, in: %i[unknown yes no partial], default: :unknown
  enumerize :visual_signs_availability, in: %i[unknown yes no partial], default: :unknown
end