# frozen_string_literal: true

RSpec.describe StopAreaDecorator, type: :decorator do
  include Pundit::PunditDecoratorPolicy

  let(:object) { Chouette::StopArea.new }

  describe '#waiting_time_text' do
    subject { decorator.waiting_time_text }

    it "returns '-' when waiting_time is nil" do
      object.waiting_time = nil
      is_expected.to eq('-')
    end

    it "returns '-' when waiting_time is zero" do
      object.waiting_time = 0
      is_expected.to eq('-')
    end

    it "returns '120 minutes' when waiting_time is 120" do
      object.waiting_time = 120
      is_expected.to eq('120 minutes')
    end
  end
end
