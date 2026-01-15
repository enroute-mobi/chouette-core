# frozen_string_literal: true

module Flamingo
  class ValidationSetup < ApplicationModel
    self.table_name = :flamingo_validation_setups

    include ::Processable

    belongs_to :workgroup, inverse_of: :flamingo_validation_setups
    has_many :validations, class_name: 'Flamingo::Validation', inverse_of: :setup, dependent: :destroy

    validates :name, :ruleset, :schema_version, :token, presence: true
    validates :name, uniqueness: { scope: %i[workgroup_id] }
    validates :schema_version, inclusion: { in: ::Secretary::Validation::SCHEMA_VERSIONS }

    class << self
      def candidate_operation_steps
        %w[before_import]
      end
    end

    def build_processed(attributes)
      validations.create!(attributes.slice(:workbench, :operation, :creator))
    end
  end
end
