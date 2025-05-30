# frozen_string_literal: true

RSpec.describe Destination, type: :model do
  it { is_expected.to belong_to(:publication_setup).optional }
  it { should have_many :reports }
  it { should validate_presence_of :type }
  it { should validate_presence_of :name }
end

RSpec.describe Destination::HttpRequest do
  subject(:http_request) { described_class.new(report, 'Test', uri) }

  let(:report) { double(:report) }
  let(:uri) { 'http://test.ex' }

  describe '#use_ssl?' do
    subject { http_request.send(:use_ssl?) }

    context 'when URL is http://test.ex' do
      it { is_expected.to eq(false) }
    end

    context 'when URL is https://test.ex' do
      let(:uri) { 'https://test.ex' }

      it { is_expected.to eq(true) }
    end
  end
end
