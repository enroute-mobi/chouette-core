# frozen_string_literal: true

RSpec.describe Contract do
  it { is_expected.to validate_presence_of(:name) }
  context '', pending: 'validate_presence_of does not support has_array_of (= nil)' do # TODO: CHOUETTE-2397
    it { is_expected.to validate_presence_of(:lines) }
  end
end
