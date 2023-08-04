module ReferentialHelper

  def first_referential
    Referential.find_by!(:slug => "first")
  end

  def first_organisation
    Organisation.find_by!(code: "first")
  end

  def first_workgroup
    Workgroup.find_by_name('IDFM')
  end

  def first_workbench
    Workbench.find_by(prefix: 'first')
  end

  def default_stop_area_referential
    StopAreaReferential.find_by_name("first")
  end

  def default_line_referential
    LineReferential.find_by_name("first")
  end

  def self.included(base)
    base.class_eval do
      extend ClassMethods
      base.let(:referential){ first_referential }
      base.let(:organisation){ first_organisation }
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
    DatabaseCleaner.clean_with :truncation, except: %w[spatial_ref_sys time_zones]
    # Truncating doesn't drop schemas, ensure we're clean here, first *may not* exist
    Apartment::Tenant.drop('first') rescue nil
    # Create the default tenant for our tests
    organisation = Organisation.create!(code: "first", name: "first")

    line_referential = LineReferential.find_or_create_by(name: "first") do |referential|
      referential.objectid_format = "netex"
      referential.add_member organisation, owner: true
    end
    stop_area_referential = StopAreaReferential.find_or_create_by(name: "first") do |referential|
      referential.objectid_format = "netex"
      referential.add_member organisation, owner: true
    end

    workgroup = FactoryBot.create(
      :workgroup,
      name: "IDFM",
      line_referential: line_referential,
      stop_area_referential: stop_area_referential,
      owner: organisation
    )

    workbench = FactoryBot.create(
      :workbench,
      name: "Gestion de l'offre",
      organisation: organisation,
      workgroup: workgroup,
      line_referential: line_referential,
      stop_area_referential: stop_area_referential,
      prefix: organisation.code
    )
    FactoryBot.create(
      :referential,
      prefix: workbench.prefix,
      name: "first",
      slug: "first",
      organisation: organisation,
      workbench: workbench,
      objectid_format: "stif_netex"
    )
  end

  config.before(:each) do |example|
    DatabaseCleaner.strategy = :transaction

    unless example.metadata[:use_chouette_factory]
      # Switch into the default tenant
      first_referential.switch
    end
  end

  config.before(:each, truncation: true) do
    DatabaseCleaner.strategy = :truncation, { except: %w[spatial_ref_sys time_zones] }
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
