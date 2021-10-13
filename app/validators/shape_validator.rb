class ShapeValidator < ActiveModel::Validator
  def validate(record)
    record.validates_length_of(:waypoints, minimum: 2)
    record.validates_with(ActiveRecord::Validations::AssociatedValidator, attributes: :waypoints)
  end

  def validate!(record)
    validate(record)

    raise ActiveRecord::RecordInvalid if record.errors.any?
  end
end
