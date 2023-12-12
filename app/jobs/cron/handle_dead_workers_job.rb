# frozen_string_literal: true

module Cron
  class HandleDeadWorkersJob < MinutesJob
    def perform_once
      ::Delayed::Heartbeat.delete_timed_out_workers
    end
  end
end
