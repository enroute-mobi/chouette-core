# frozen_string_literal: true

RSpec.describe Import::Message, :type => :model do
  it { should validate_presence_of(:criticity) }
  it { is_expected.to belong_to(:import).optional }
  it { is_expected.to belong_to(:resource).optional }
end
