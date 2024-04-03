unless ENV['NO_RCOV']
  require 'simplecov'

  SimpleCov.start 'rails' do
    if ENV['CODACY_PROJECT_TOKEN']
      require 'simplecov-cobertura'
      formatter SimpleCov::Formatter::CoberturaFormatter
    end

    enable_coverage :branch
    add_filter 'vendor'

    #command_name "Job #{ENV["TEST_ENV_NUMBER"]}" if ENV["TEST_ENV_NUMBER"]
    #formatter SimpleCov::Formatter::SimpleFormatter
  end
end

ENV["RAILS_ENV"] = 'test'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'

if ENV['DD_ENV']
  require 'datadog/ci'

  Datadog.configure do |c|
    c.ci.enabled = true
    c.service = ENV.fetch 'BITBUCKET_REPO_SLUG', 'chouette-core'
    c.ci.instrument :rspec
  end
end

# Add additional requires below this line. Rails is not loaded until this point!
# Add this to load Capybara integration:
require 'active_attr/rspec'
require 'capybara/poltergeist'
require 'capybara/rails'
require 'capybara/rspec'
require 'webmock/rspec'
require 'will_paginate/array'

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
#
# The following line is provided for convenience purposes. It has the downside
# of increasing the boot-up time by auto-requiring all files in the support
# directory. Alternatively, in the individual `*_spec.rb` files, manually
# require only the support files necessary.
#
Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

# Checks for pending migrations before tests are run.
# If you are not using ActiveRecord, you can remove this line.
ActiveRecord::Migration.maintain_test_schema!

RSpec.configure do |config|
  #Capybara.exact = true
  Capybara.javascript_driver = :poltergeist
  # :meta tests can be run seperately in case of doubt about the tests themselves
  # they serve mainly as an explanataion of complicated tests (as e.g. PG information_schema introspection)
  config.filter_run_excluding meta: true
  config.filter_run_excluding truncation: true
  config.filter_run_excluding wip: true
  config.run_all_when_everything_filtered = true

  config.include EmailSpec::Helpers, type: :mailer
  config.include EmailSpec::Matchers, type: :mailer

  config.filter_run focus: true
  config.run_all_when_everything_filtered = true

  # ## Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = false

  # RSpec Rails can automatically mix in different behaviours to your tests
  # based on their file location, for example enabling you to call `get` and
  # `post` in specs under `spec/controllers`.
  #
  # You can disable this behaviour by removing the line below, and instead
  # explicitly tag your specs with their type, e.g.:
  #
  #     RSpec.describe UsersController, type: :controller do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://relishapp.com/rspec/rspec-rails/docs
  config.infer_spec_type_from_file_location!
end

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    # Choose a test framework:
    with.test_framework :rspec
    # with.test_framework :minitest
    # with.test_framework :minitest_4
    # with.test_framework :test_unit

    # Choose one or more libraries:
    # with.library :active_record
    # with.library :active_model
    # with.library :action_controller
    # Or, choose the following (which implies all of the above):
    with.library :rails
  end
end
