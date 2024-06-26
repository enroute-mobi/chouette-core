# frozen_string_literal: true

class Workbench
  class Sharing < ApplicationModel
    self.table_name = 'workbench_sharings'

    belongs_to :workbench, inverse_of: :sharings, required: true
    belongs_to :recipient, polymorphic: true, inverse_of: :workbench_sharings

    validates :name, presence: true
    validates :workbench_id, uniqueness: { scope: %i[recipient_type recipient_id] }, if: :recipient_id?
    validates :recipient_type, inclusion: { in: %w[User Organisation] }
    validates :invitation_code, presence: true, uniqueness: true, if: :pending?

    before_validation :create_invitation_code, on: :create, if: :pending?

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

    private

    def create_invitation_code
      self.invitation_code ||= "S-#{3.times.map { format('%03d', SecureRandom.random_number(1000)) }.join('-')}"
    end
  end
end
