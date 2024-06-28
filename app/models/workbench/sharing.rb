# frozen_string_literal: true

class Workbench
  class Sharing < ApplicationModel
    self.table_name = 'workbench_sharings'

    belongs_to :workbench, inverse_of: :sharings, required: true
    belongs_to :recipient, polymorphic: true, inverse_of: :workbench_sharings

    before_validation :create_invitation_code, on: :create, if: :pending?

    validates :name, presence: true
    validates :recipient_type, inclusion: { in: %w[User Organisation] }
    validates :recipient_id, uniqueness: { scope: %i[workbench_id recipient_type] }, if: :recipient_id?
    validate :validate_user_recipient_id, on: :create, if: :validate_user_recipient_id?
    validates :recipient_id, absence: true, on: :create, if: :validate_organisation_recipient_id?
    validates :invitation_code, presence: true, uniqueness: true, if: :pending?

    class << self
      def model_name
        ActiveModel::Name.new(self, parent)
      end
    end

    def pending?
      recipient_id.blank?
    end

    def status
      if pending?
        :pending
      else
        :confirmed
      end
    end

    def candidate_user_recipients
      workbench&.workgroup&.owner&.users || User.none
    end

    private

    def create_invitation_code
      self.invitation_code ||= "S-#{3.times.map { format('%03d', SecureRandom.random_number(1000)) }.join('-')}"
    end

    def validate_recipient_id?
      recipient_id && validation_context != :test
    end

    def validate_user_recipient_id?
      validate_recipient_id? && recipient_type == 'User'
    end

    def validate_organisation_recipient_id?
      validate_recipient_id? && recipient_type == 'Organisation'
    end

    def validate_user_recipient_id
      return if candidate_user_recipients.exists?(recipient_id)

      errors.add(:recipient_id, :invalid)
    end
  end
end
