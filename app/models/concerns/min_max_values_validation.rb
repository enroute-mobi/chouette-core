module MinMaxValuesValidation
  extend ActiveSupport::Concern

  included do
    validate :min_max_values_validation
  end

  def min_max_values_validation
    return true unless minimum && maximum
    return true unless maximum < minimum
    errors.add(:min_max_values, I18n.t('compliance_controls.min_max_values', min: minimum, max: maximum))
  end
end
