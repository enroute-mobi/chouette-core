# frozen_string_literal: true

module ProcessingRule
  class FlamingoValidationProcessingSetup < ProcessingSetup
    attribute :ruleset, :string
    attribute :include_schema, :boolean, default: false
    attribute :schema_version, :string
    attribute :token, :string

    validates :ruleset, :schema_version, :token, presence: true
    validates :schema_version, inclusion: { in: ::Secretary::Validation::SCHEMA_VERSIONS }

    class << self
      def candidate_operation_steps
        %w[before_import]
      end
    end

    def processed_klass
      ::Flamingo::Validation
    end
  end
end
