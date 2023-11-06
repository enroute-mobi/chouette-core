# frozen_string_literal: true

module Cron
  class HourlyJob < BaseJob
    self.abstract_class = true

    cron '0 * * * *'
  end
end
