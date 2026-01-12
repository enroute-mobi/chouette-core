# frozen_string_literal: true

module Flamingo
  class Validation < Operation
    self.table_name = :flamingo_validations

    belongs_to :setup, class_name: 'Flamingo::ValidationSetup'
    belongs_to :workbench, inverse_of: :flamingo_validations
    belongs_to :operation, polymorphic: true

    def flamingo_server
      @flamingo_server ||= ::Secretary::Server.create(token: setup.token)
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
        ruleset: setup.ruleset,
        include_schema: setup.include_schema,
        schema_version: setup.schema_version,
        publish: true
      )
    end

    class Error < StandardError; end
  end
end
