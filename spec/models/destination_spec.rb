# frozen_string_literal: true

RSpec.describe Destination, type: :model do
  it { is_expected.to belong_to(:publication_setup).optional }
  it { should have_many :reports }
  it { should validate_presence_of :type }
  it { should validate_presence_of :name }
end
