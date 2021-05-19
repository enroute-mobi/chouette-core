RSpec.describe RouteCalculateCostsService do

  let(:organisation) { Organisation.new }
  let(:referential) { Referential.new organisation: organisation }
  subject(:service) { RouteCalculateCostsService.new(referential) }

  describe "#disabled?" do

    subject { service.disabled? }

    context "when associated Referential is merged or aggregated dataset" do
      before do
        allow(referential).to receive(:in_referential_suite?).and_return(true)
      end
      it { is_expected.to be_truthy }
    end

    context "when associated Organisation doesn't have the route_calculate_costs feature" do
      it { is_expected.to be_truthy }
    end

    context "when associated Organisation doesn't have the costs_in_journey_patterns feature" do
      it { is_expected.to be_truthy }
    end

    context "with a user dataset and an Organisation with route_calculate_costs and costs_in_journey_patterns features" do
      before do
        allow(referential).to receive(:in_referential_suite?).and_return(false)
        organisation.features << "route_calculate_costs" << "costs_in_journey_patterns"
      end

      it { is_expected.to be_falsy }
    end

  end

  describe "#update" do

    it "doesn't create a job when the service is disabled" do
      expect(service).to receive(:disabled?).and_return(true)
      expect(RouteCalculateCostsJob).to_not receive(:new)

      service.update(42)
    end

  end

  describe "#update_all" do

    it "doesn't create any job when the service is disabled" do
      expect(service).to receive(:disabled?).and_return(true)
      expect(RouteCalculateCostsJob).to_not receive(:new)

      service.update_all
    end

  end

end
