# frozen_string_literal: true

module Cron
  class DestroyDeletedAtWorkgroupsJob < DailyJob
    def perform_once
      Workgroup.where.not(deleted_at: nil).find_each(&:destroy)
    end
  end
end
