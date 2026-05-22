RSpec.describe StopAreaProvider, type: :model do
  describe "#allowed_stop_area_types" do
    subject(:stop_area_provider) do
      create(:stop_area_provider, allowed_stop_area_types: %w[zdep zdlp])
    end

    it "normalizes blank and duplicate values" do
      stop_area_provider.allowed_stop_area_types = ["zdep", "", "zdep", :zdlp]

      expect(stop_area_provider.allowed_stop_area_types).to eq(%w[zdep zdlp])
    end

    it "keeps nil as all allowed types" do
      stop_area_provider.allowed_stop_area_types = nil

      expect(stop_area_provider.allowed_stop_area_types).to be_nil
    end

    it "stores all selected types as nil" do
      stop_area_provider.allowed_stop_area_types = Chouette::AreaType::ALL.reverse

      expect(stop_area_provider.allowed_stop_area_types).to be_nil
    end

    it "is invalid when an existing Stop Area uses a disallowed type" do
      create(:stop_area, :zdep, stop_area_provider: stop_area_provider)

      stop_area_provider.allowed_stop_area_types = %w[zdlp]

      expect(stop_area_provider).not_to be_valid
      expect(stop_area_provider.errors).to have_key(:allowed_stop_area_types)
    end
  end

  describe "#allowed_stop_area_types_must_be_known" do
    subject(:stop_area_provider) do
      build(:stop_area_provider, allowed_stop_area_types: allowed_stop_area_types)
    end

    context "when all allowed stop area types are known" do
      let(:allowed_stop_area_types) { %w[zdep zdlp] }

      it "does not add an error" do
        stop_area_provider.valid?

        expect(stop_area_provider.errors).not_to have_key(:allowed_stop_area_types)
      end
    end

    context "when an allowed stop area type is unknown" do
      let(:allowed_stop_area_types) { %w[zdep unknown] }

      it "adds an error" do
        expect(stop_area_provider).not_to be_valid
        expect(stop_area_provider.errors).to have_key(:allowed_stop_area_types)
      end
    end
  end

  describe "#effective_allowed_stop_area_types" do
    subject(:stop_area_provider) do
      build(:stop_area_provider, allowed_stop_area_types: allowed_stop_area_types)
    end

    context 'when allowed stop area types are nil' do
      let(:allowed_stop_area_types) { nil }

      it "returns all area types when allowed stop area types are nil" do
        expect(stop_area_provider.effective_allowed_stop_area_types).to eq(Chouette::AreaType::ALL.map(&:to_s))
      end
    end

    context 'when allowed stop area types are specified' do
      let(:allowed_stop_area_types) { %w[zdep zdlp] }

      it "returns the specified allowed stop area types" do
        expect(stop_area_provider.effective_allowed_stop_area_types).to eq(allowed_stop_area_types)
      end
    end
  end

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
