module ReferentialHelper

  def first_referential
    Referential.find_by!(:slug => "first")
  end

  def first_organisation
    Organisation.find_by!(code: "first")
  end

  def self.included(base)
    base.class_eval do
      extend ClassMethods
      alias_method :referential, :first_referential
      alias_method :organisation, :first_organisation
    end
  end

  module ClassMethods

    def assign_referential
      before(:each) do
        assign :referential, referential
      end
    end
    def assign_organisation
      before(:each) do
        assign :organisation, referential.organisation
      end
    end

  end

end

RSpec.configure do |config|
  config.include ReferentialHelper

  config.before(:suite) do
    # Clean all tables to start
    DatabaseCleaner.clean_with :truncation, except: %w[spatial_ref_sys]
    # Truncating doesn't drop schemas, ensure we're clean here, first *may not* exist
    Apartment::Tenant.drop('first') rescue nil
    # Create the default tenant for our tests
    organisation = Organisation.create!(code: "first", name: "first")

    line_referential = LineReferential.find_or_create_by(name: "first") do |referential|
      referential.objectid_format = "stif_codifligne"
      referential.add_member organisation, owner: true
    end
    stop_area_referential = StopAreaReferential.find_or_create_by(name: "first") do |referential|
      referential.objectid_format = "stif_reflex"
      referential.add_member organisation, owner: true
    end

    workbench = FactoryGirl.create(
      :workbench,
      name: "Gestion de l'offre",
      organisation: organisation,
      line_referential: line_referential,
      stop_area_referential: stop_area_referential
    )
    FactoryGirl.create(
      :referential,
      prefix: "first",
      name: "first",
      slug: "first",
      organisation: organisation,
      workbench: workbench,
      objectid_format: "stif_netex"
    )
  end

  # Alas this still might not be sufficiant in certain cases (interruption of tests)
  # to fix the problem of `rake db:rollback; rake db:migrate`. However the test database
  # can also be cleanded by means of
  # ```
  #    RAILS_ENV=test bundle exec ruby -I. -r environment.rb -e 'Referential.pluck(:slug).each{|s|Apartment::Tenant.drop(n)};Referential.delete_all'` 
  #
  config.after :suite do
    Referential.pluck(:slug).each do |name|
      Apartment::Tenant.drop(name) rescue nil
    end
    Referential.delete_all
  end

  config.before(:each) do
    DatabaseCleaner.strategy = :transaction
    # Switch into the default tenant
    first_referential.switch
  end

  config.before(:each, truncation: true) do
    DatabaseCleaner.strategy = :truncation, { except: %w[spatial_ref_sys] }
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    # Reset tenant back to `public`
    Apartment::Tenant.reset
    # Rollback transaction
    DatabaseCleaner.clean
  end

end
