# frozen_string_literal: true

class Subscription
  include ActiveModel::Model

  def self.enabled?
    Chouette::Config.subscription.enabled?
  end

  attr_accessor :organisation_name, :user_name, :email, :password, :password_confirmation, :workbench_invitation_code

  validate do |subscription|
    [OrganisationValidator, UserValidator, WorkbenchConfirmationValidator].each do |validator|
      validator.validate subscription
    end
  end

  def organisation
    @organisation ||= Organisation.new(
      name: organisation_name,
      code: organisation_name&.parameterize,
      features: Feature.all
    )
  end

  def user
    @user ||= organisation.users.build(
      name: user_name,
      email: email,
      password: password,
      password_confirmation: password_confirmation,
      profile: :admin
    )
  end

  def workbench_confirmation
    return unless workbench_invitation_code.present?

    @workbench_confirmation ||= Workbench::Confirmation.new(
      invitation_code: workbench_invitation_code,
      organisation: organisation,
      user: user
    )
  end

  def workgroup
    @workgroup ||= Workgroup.create_with_organisation(organisation)
  end

  def save
    return false unless valid?

    ActiveRecord::Base.transaction do
      organisation.save!
      user.save!

      if workbench_confirmation
        workbench_confirmation.save!
      else
        workgroup.save!
      end

      SubscriptionMailer.new_subscription(user)
    end

    true
  end

  # ActiveModel::Validator isn't instance oriented ..
  # We can't share methods like add_errors ..
  class Validator
    def self.validate(subscription)
      new(subscription).validate
    end

    attr_reader :subscription

    def initialize(subscription)
      @subscription = subscription
    end

    delegate :errors, to: :subscription

    def add_errors(on:, from:)
      from.each { |e| errors.add(on, e) }
    end
  end

  class OrganisationValidator < Validator
    delegate :organisation, to: :subscription

    def validate
      return if organisation.valid?

      %i[name code].each do |attribute|
        add_errors on: :organisation_name, from: organisation.errors[attribute]
      end
    end
  end

  class UserValidator < Validator
    delegate :user, to: :subscription

    def validate
      return if user.valid?

      %i[password password_confirmation email].each do |attribute|
        add_errors on: attribute, from: user.errors[attribute]
      end

      add_errors on: :user_name, from: user.errors[:name]
    end
  end

  class WorkbenchConfirmationValidator < Validator
    delegate :workbench_confirmation, to: :subscription

    def validate
      return if workbench_confirmation.nil? || workbench_confirmation.valid?

      add_errors on: :workbench_invitation_code, from: workbench_confirmation.errors[:invitation_code]
    end
  end
end
