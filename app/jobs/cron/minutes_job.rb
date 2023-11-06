# frozen_string_literal: true

module Cron
  class MinutesJob < BaseJob
    self.abstract_class = true

    cron '*/5 * * * *'
  end
end
