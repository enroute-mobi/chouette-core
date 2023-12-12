# frozen_string_literal: true

module Cron
  class PurgeReferentialJob < DailyJob
    def perform_once
      ::Referential.clean!
    end
  end
end
