# frozen_string_literal: true

module Cron
  class StartBlockedPendingMergesJob < MinutesJob
    MAX_MERGES_TO_CHECK = 10

    def perform_once
      ::Workbench.find_each do |workbench|
        last_merge_statuses = workbench.merges.order(created_at: :desc).first(MAX_MERGES_TO_CHECK).pluck(:status).uniq
        next unless last_merge_statuses == %w[pending successful]

        oldest_pending_merge = workbench.merges.where(status: 'pending').order(created_at: :asc).first
        Rails.logger.warn("Force Merge start for Merge##{oldest_pending_merge.id} in Workbench##{workbench.id}")
        oldest_pending_merge.merge
      end
    end
  end
end
