#
# Usage:
#   expect(model).to exist_in_database
#
RSpec::Matchers.define :exist_in_database do

  match do |actual|
    actual.class.exists?(actual.id)
  end

end

RSpec::Matchers.alias_matcher :an_array_including, :include
RSpec::Matchers.define_negated_matcher :an_array_excluding, :include
