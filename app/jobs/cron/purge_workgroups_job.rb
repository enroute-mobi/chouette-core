# frozen_string_literal: true

module Cron
  class PurgeWorkgroupsJob < DailyJob
    def perform_once
      ::Workgroup.purge_all
    end
  end
end
