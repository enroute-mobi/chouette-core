# frozen_string_literal: true

RSpec.describe ProcessingRule::FlamingoValidationProcessingSetup do
  it { is_expected.to validate_presence_of(:ruleset) }
  it { is_expected.to validate_presence_of(:schema_version) }
  it { is_expected.to validate_presence_of(:token) }
  it { is_expected.to validate_inclusion_of(:schema_version).in_array(%w[master next]) }
end
