# frozen_string_literal: true

RSpec.describe Flamingo::ValidationSetup do
  it { is_expected.to belong_to(:workgroup) }

  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_presence_of(:ruleset) }
  it { is_expected.to validate_presence_of(:schema_version) }
  it { is_expected.to validate_presence_of(:token) }
  it { is_expected.to validate_inclusion_of(:schema_version).in_array(%w[master next]) }
end
