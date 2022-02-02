# coding: utf-8
class Subscription
  include ActiveModel::Model

  validates_with SubscriptionValidator

  def self.enabled?
    Rails.application.config.accept_user_creation
  end

  attr_accessor :organisation_name, :user_name, :email, :password, :password_confirmation, :workbench_confirmation_code

  def user
    @user ||= organisation.users.build name: user_name, email: email, password: password, password_confirmation: password_confirmation, profile: :admin
  end

  def organisation
    @organisation ||= Organisation.new name: organisation_name, code: organisation_name.parameterize, features: Feature.all
  end

  def workgroup
    @workgroup ||= Workgroup.create_with_organisation(organisation)
  end

  alias_method :create_workgroup!, :workgroup

  def save
    return false unless valid?

    ActiveRecord::Base.transaction do
      organisation.save!
      user.save!

      if workbench_confirmation_code.present?
        Workbenches::AcceptInvitation.new(confirmation_code: workbench_confirmation_code, organisation_id: organisation.id).call
      else
        create_workgroup!
      end 

      SubscriptionMailer.new_subscription(user)
    end

    true
  end

end
