RSpec.describe StopAreaProvider, type: :model do
  describe "#used?" do
    subject { stop_area_provider.used? }

    context "when a Stop Area is associated" do
      let(:context) { Chouette.create { stop_area } }
      let(:stop_area_provider) { context.stop_area.stop_area_provider }

      it { is_expected.to be_truthy }
    end

    context "when a Connection Link is associated", pending: true do
      let(:context) { Chouette.create { connection_link } }
      let(:stop_area_provider) { context.connection_link.stop_area_provider }

      it { is_expected.to be_truthy }
    end

    context "when a Stop Area Routing Constraint is associated", pending: true do
      let(:context) { Chouette.create { stop_area_routing_constraint } }
      let(:stop_area_provider) { context.stop_area_routing_constraint.stop_area_provider }

      it { is_expected.to be_truthy }
    end

    context "when a Entrance is associated" do
      let(:context) { Chouette.create { entrance } }
      let(:stop_area_provider) { context.entrance.stop_area_provider }

      it { is_expected.to be_truthy }
    end

    context "when no resource is associated" do
      let(:context) { Chouette.create { stop_area_provider } }
      let(:stop_area_provider) { context.stop_area_provider }

      it { is_expected.to be_falsy }
    end
  end
end
