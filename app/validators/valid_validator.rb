class ValidValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    if value && !value.valid?
      record.errors.add attribute, (options[:message] || "is not valid")
    end
  end
end
