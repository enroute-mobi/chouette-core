# frozen_string_literal: true

module Cron
  class DailyJob < BaseJob
    self.abstract_class = true

    cron '0 3 * * *'
  end
end
