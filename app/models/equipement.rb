# frozen_string_literal: true

class Equipement < ApplicationModel
  include ShapeReferentialSupport
  include CodeSupport
  extend Enumerize

  belongs_to :stop_area, class_name: 'Chouette::StopArea' # CHOUETTE-3247 optional: false

  enumerize :mobility_impaired_accessibility, in: %i[unknown yes no partial], default: :unknown
  enumerize :wheelchair_accessibility, in: %i[unknown yes no partial], default: :unknown
  enumerize :step_free_accessibility, in: %i[unknown yes no partial], default: :unknown
  enumerize :escalator_free_accessibility, in: %i[unknown yes no partial], default: :unknown
  enumerize :lift_free_accessibility, in: %i[unknown yes no partial], default: :unknown
  enumerize :audible_signals_availability, in: %i[unknown yes no partial], default: :unknown
  enumerize :visual_signs_availability, in: %i[unknown yes no partial], default: :unknown

  validates :name, presence: true
end
