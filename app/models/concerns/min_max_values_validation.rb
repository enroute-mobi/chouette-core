module MinMaxValuesValidation
  extend ActiveSupport::Concern

  included do
    validates_presence_of :minimum, :maximum
    validate :min_max_values_validation
  end

  def min_max_values_validation
    return true if (minimum && maximum) && (minimum.to_i < maximum.to_i)
    errors.add(:minimum, I18n.t('compliance_controls.min_max_values', min: minimum, max: maximum))
  end
end
