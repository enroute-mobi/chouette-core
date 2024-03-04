# frozen_string_literal: true

RSpec.describe Contract do
  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_presence_of(:lines) }
end
