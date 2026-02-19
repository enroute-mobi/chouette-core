# frozen_string_literal: true

module Import
  class Processor < ::Processor
    def after
      super unless skip_after_import?
    end

    protected

    def before_referentials
      nil
    end

    def after_referentials
      [operation.referential].compact
    end

    def skip_after_import?
      # We should check operation for Import::NetexGeneric and resources for Import::Gtfs and Import::Neptune
      # Import::Gtfs and Import::Neptune don't update their statuses before processor begin
      operation.failed? || operation.resource_status.include?(:ERROR)
    end

  end
end
