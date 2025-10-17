# frozen_string_literal: true

RSpec.configure do |config|
  config.before(:each) do
    DatabaseCleaner.strategy = :transaction
  end

  config.before(:each, truncation: true) do
    DatabaseCleaner.strategy = :truncation, { except: %w[spatial_ref_sys time_zones] }
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each, truncation: true) do
    Apartment::Tenant.each do |tenant|
      Apartment::Tenant.drop(tenant)
    end
  end

  config.after(:each) do
    # Reset tenant back to `public`
    Apartment::Tenant.reset
    # Rollback transaction
    DatabaseCleaner.clean
  end
end
