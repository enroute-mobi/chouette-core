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
      @flamingo_server_validation = create_validation

      self.validation_id = @flamingo_server_validation.id
      self.validation_report_url = @flamingo_server_validation.report_url
      save!
    end

    def final_user_status
      if @flamingo_server_validation
        if @flamingo_server_validation.user_status == 'pending'
          Operation.user_status.failed
        else
          @flamingo_server_validation.user_status
        end
      else
        super
      end
    end

    private

    def create_validation
      operation.file.cache!
      flamingo_server.validate(
        operation.file.path,
        ruleset: setup.ruleset,
        include_schema: setup.include_schema,
        schema_version: setup.schema_version,
        schema_ignore: setup.ignored_schema_rules_list,
        publish: true
      )
    end
  end
end
