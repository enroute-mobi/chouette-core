# frozen_string_literal: true

module Import
  class Processor < ::Processor
    protected

    def before_referentials
      nil
    end

    def after_referentials
      [operation.referential].compact
    end

    def after
      perform_processing_rules(after_processing_rules, after_referentials) unless skip_after_import?
    end

    def skip_after_import?
      operation.failed? || operation.resource_status.include?(:ERROR)
    end

  end
end
