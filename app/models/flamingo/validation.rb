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
      self.error_uuid = SecureRandom.uuid unless validation.successful?
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
        ignored_schema_rules: setup.ignored_schema_rules_list,
        publish: true
      )
    end
  end
end
