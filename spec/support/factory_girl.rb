# frozen_string_literal: true

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
end

FactoryBot::SyntaxRunner.class_eval do
  include ActiveSupport::Testing::FileFixtures
end

RSpec.configure do |config|
  config.before(:suite) do
    FactoryBot::SyntaxRunner.file_fixture_path = RSpec.configuration.file_fixture_path
  end
end
