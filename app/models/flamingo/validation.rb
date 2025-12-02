# frozen_string_literal: true

module Flamingo
  class Validation < Operation
    self.table_name = :flamingo_validations

    belongs_to :workbench, inverse_of: :flamingo_validations
    belongs_to :processing_rule, class_name: 'ProcessingRule::Base', inverse_of: :flamingo_validations
    belongs_to :operation, polymorphic: true

    delegate :processing_setup, to: :processing_rule

    def flamingo_server
      @flamingo_server ||= ::Secretary::Server.create(token: processing_setup.token)
    end

    def perform
      validation = create_validation

      self.validation_id = validation.id
      self.validation_report_url = validation.report_url
      raise Error unless validation.successful?
    rescue Error => e
      self.error_uuid = Chouette::Safe.capture("Flamingo Validation #{validation.id} failed", e)
    ensure
      save!
    end

    private

    def create_validation
      operation.file.cache!
      flamingo_server.validate(
        operation.file.path,
        ruleset: processing_setup.ruleset,
        include_schema: processing_setup.include_schema,
        schema_version: processing_setup.schema_version,
        publish: true
      )
    end

    class Error < StandardError; end
  end
end
