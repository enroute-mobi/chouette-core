# frozen_string_literal: true

module Cron
  class CheckDeadOperationsJob < MinutesJob
    def perform_once
      # check_ccset_operations
      # ::ParentNotifier.new(ComplianceCheckSet).notify_when_finished
      ::ComplianceCheckSet.abort_old

      # check_import_operations
      ::Import::Netex.abort_old
      ::ParentNotifier.new(Import::Netex).notify_when_finished
    end
  end
end
