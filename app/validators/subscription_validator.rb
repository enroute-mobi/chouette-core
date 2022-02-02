class SubscriptionValidator < ActiveModel::Validator
  def validate(record)
    ValidationService.call(record)
  end

  class ValidationService
    attr_reader :record

    delegate :user, :organisation, :errors, to: :record

    def initialize record
      @record = record
    end

    def self.call record
      new(record).call
    end

     def call
      validate_organisation
      validate_user
      validate_workgroup_confirmation_code
    end

    private

    def validate_organisation
      return if organisation.valid?

      %i[name code].each do |attribute|
        add_errors on: :organisation_name, from: organisation.errors[attribute]
      end
    end

    def validate_user
      return if user.valid?

      %i[password password_confirmation email].each do |attribute|
        add_errors on: attribute, from: user.errors[attribute]
      end

      add_errors on: :user_name, from: user.errors[:name]
    end

    def validate_workgroup_confirmation_code
      return unless record.workbench_confirmation_code

      code_is_valid = Workbench.where(invitation_code: record.workbench_confirmation_code).exists?

      record.errors.add(:workbench_confirmation_code) unless code_is_valid
    end

    def add_errors(on:, from:)
      from.each { |e|  record.errors.add(on, e) }
    end
  end
end
