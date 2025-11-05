# frozen_string_literal: true

RSpec.configure do |config|
  config.before(:each) do
    if self.class.metadata[:truncation]
      DatabaseCleaner.strategy = :truncation, { except: %w[spatial_ref_sys time_zones] }
    else
      DatabaseCleaner.strategy = :transaction
    end
    DatabaseCleaner.start
  end

  config.after(:each) do
    # Reset tenant back to `public`
    Apartment::Tenant.reset
    if self.class.metadata[:truncation]
      Apartment.tenant_names.each do |tenant|
        Apartment::Tenant.drop(tenant) rescue Apartment::TenantNotFound # rubocop:disable Style/RescueModifier
      end
    end
    # Rollback transaction
    DatabaseCleaner.clean
  end
end
