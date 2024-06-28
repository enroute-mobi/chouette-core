#!/usr/bin/env ruby

RSpec.configure do |config|
  config.around :example, :timezone do |example|
    timezone = example.metadata[:timezone]
    timezone = ActiveSupport::TimeZone.all.sample if timezone == :random
    Time.use_zone(timezone) { example.run }
  end
end
