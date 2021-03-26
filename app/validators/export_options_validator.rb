class OptionsValidator < ActiveModel::Validator
  def validate(record)
    if some_complex_logic
      record.errors.add(:base, "This record is invalid")
    end
  end
end