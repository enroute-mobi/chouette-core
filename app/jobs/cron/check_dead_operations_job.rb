# frozen_string_literal: true

module Cron
  class CheckDeadOperationsJob < MinutesJob
    def perform_once
      # check_import_operations
      ::Import::Netex.abort_old
      ::ParentNotifier.new(Import::Netex).notify_when_finished
    end
  end
end
