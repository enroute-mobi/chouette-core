# frozen_string_literal: true

RSpec.describe ConnectionLinkDecorator, type: :decorator do
  include Pundit::PunditDecoratorPolicy

  let(:object) { Chouette::ConnectionLink.new }

  describe "#name" do
    subject { decorator.name }

    before do
      allow(object).to receive(:default_name).and_return('Default Name')
    end

    context "when the name is empty" do
      before { object.name = '' }
      it "uses the default name" do
        is_expected.to eq(object.default_name)
      end
    end

    context "when the name is present" do
      before { object.name = 'Not Empty' }
      it "uses the name" do
        is_expected.to eq(object.name)
      end
    end
  end
end
