class SubscriptionValidator < ActiveModel::Validator
  def validate(record)
    validate_organisation(record)
    validate_user(record)
  end

  private

  def validate_organisation(record)
    unless record.organisation.valid?
      %i[name code].each do |attribute|
        record.organisation.errors[attribute].each do |e|
          record.errors.add(:organisation_name, e)
        end
      end
    end
  end

  def validate_user(record)
    unless record.user.valid?
      %i[password password_confirmation email].each do |attribute|
        record.user.errors[attribute].each do |e|
          record.errors.add(attribute, e)
        end
      end

      record.user.errors[:name].each do |e|
        record.errors.add :user_name, e
      end
    end
  end
end