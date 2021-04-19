RSpec.describe ConnectionLinkDecorator do

  let(:connection_link) { Chouette::ConnectionLink.new }
  let(:decorator) { connection_link.decorate }

  describe "#name" do
    subject { decorator.name }

    before do
      allow(connection_link).to receive(:default_name).and_return("Default Name")
    end

    context "when the name is empty" do
      before { connection_link.name = "" }
      it "uses the default name" do
        is_expected.to eq(connection_link.default_name)
      end
    end

    context "when the name is present" do
      before { connection_link.name = "Not Empty" }
      it "uses the name" do
        is_expected.to eq(connection_link.name)
      end
    end
  end
end