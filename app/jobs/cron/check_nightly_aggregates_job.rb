# frozen_string_literal: true

module Cron
  class CheckNightlyAggregatesJob < MinutesJob
    class << self
      def enabled
        false
      end
    end
  end
end
