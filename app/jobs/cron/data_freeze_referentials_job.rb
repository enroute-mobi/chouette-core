# frozen_string_literal: true

module Cron
  class DataFreezeReferentialsJob < DailyJob
    def perform_once
      ::Referential.data_freeze_candidates.find_each do |referential|
        referential.data_freeze
      end
    end
  end
end
