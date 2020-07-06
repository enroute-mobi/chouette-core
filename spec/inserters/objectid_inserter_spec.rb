RSpec.describe ObjectidInserter do

  let(:referential) { double "Referential" }
  subject(:inserter) { ObjectidInserter.new referential }

  describe "#insert" do

    context "when model doesn't support objectid" do

      let(:model) { Chouette::VehicleJourneyAtStop.new }

      it "ignores the given model" do
        inserter.insert model
      end

    end

    context "when model objectid is already defined" do

      let(:model) { Chouette::VehicleJourney.new objectid: 'defined' }

      it "leaves unchanged the defined objectid" do
        expect { inserter.insert model }.to_not change(model, :objectid)
      end

    end

    describe "when model objectid is not defined" do

      let(:model) { Chouette::VehicleJourney.new }
      let(:new_objectid) { 'chouette:VehicleJourney:16e2eb20-2f3a-4011-8af7-592386bcd6e7:LOC' }

      it "defines a new objectid" do
        expect(inserter).to receive(:new_objectid).with(model).and_return(new_objectid)
        expect { inserter.insert model }.to change(model, :objectid).from(nil).to(new_objectid)
      end

    end

  end

  describe "#new_objectid" do

    let(:model) { Chouette::Route.new }

    it "uses the objectid formatter to create a new objectid" do
      allow(referential).to receive(:objectid_formatter).and_return Chouette::ObjectidFormatter::Netex.new
      expect(inserter.new_objectid(model)).to match(/chouette:Route:\b[0-9a-f]{8}\b-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-\b[0-9a-f]{12}\b:LOC/)
    end

    context "when objectid formatter is a StifNetex" do

      # Required by Route#local_id
      let(:line) { double get_objectid: double(local_id: 'test') }
      before { allow(model).to receive(:line).and_return(line) }

      before { allow(referential).to receive(:objectid_formatter).and_return Chouette::ObjectidFormatter::StifNetex.new }

      it "create a new objectid" do
        model.id = 42
        expect(inserter.new_objectid(model)).to eq("first:Route:local-1-test-42:LOC")
      end

    end

  end

end
