# frozen_string_literal: true

module Cron
  class CheckNightlyAggregatesJob < MinutesJob
    def perform_once
      ::Workgroup.where(nightly_aggregate_enabled: true).find_each(&:nightly_aggregate!)
    end
  end
end
