module Support
  module FixturesHelper
    def fixtures_path *segments
      Rails.root.join( fixture_path, *segments )
    end

    def read_fixture *segments
      File.read(fixtures_path(*segments))
    end
  end
end

RSpec.configure do |c|
  c.include Support::FixturesHelper
end
