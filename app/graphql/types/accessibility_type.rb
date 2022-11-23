module Types
  class AccessibilityType < Types::BaseObject
    description "A Chouette StopArea Accessibility"

    field :mobility_impaired_accessibility, String, null:true 
    field :wheelchair_accessibility, String, null: true
    field :step_free_accessibility, String, null: true
    field :escalator_free_accessibility, String, null: true
    field :lift_free_accessibility, String, null: true
    field :audible_signals_availability, String, null: true
    field :visual_signs_availability, String, null: true
    field :accessibility_limitation_description, String, null: true
  end
end