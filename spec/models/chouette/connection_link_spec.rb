describe Chouette::ConnectionLink, type: :model do

  subject (:connection_link){ create(:connection_link) }

  let(:stop_area) { create :stop_area }

  it "should have a valid factory" do
    expect(subject).to be_valid
  end

  describe "validations" do
    it { should belong_to(:stop_area_referential).required }
    it { should validate_presence_of :default_duration }
    it { should validate_presence_of :departure_id }
    it { should validate_presence_of :arrival_id }

    it "should have different departure and arrival" do
      expect{ create(:connection_link, departure: stop_area, arrival: stop_area) }.to raise_error ActiveRecord::RecordInvalid
    end
  end

  describe "#connection_link_type" do
    def self.legacy_link_types
      %w{Underground Mixed Overground}
    end

    legacy_link_types.each do |link_type|
      context "when link_type is #{link_type}" do
        connection_link_type = Chouette::ConnectionLinkType.new(link_type.underscore)
        it "should be #{connection_link_type}" do
          subject.link_type = link_type
          expect(subject.connection_link_type).to eq(connection_link_type)
        end
      end
    end

    context "when link_type is nil" do
      it "should be nil" do
        subject.link_type = nil
        expect(subject.connection_link_type).to be_nil
      end
    end
  end

  describe "#connection_link_type=" do
    it "should change link_type with ConnectionLinkType#name" do
      subject.connection_link_type = "Test"
      expect(subject.link_type).to eq("Test")
    end
  end

  describe "#default_name" do

    subject { connection_link.default_name }

    before do
      connection_link.departure.name = "Departure"
      connection_link.arrival.name = "Arrival"
    end

    context "when the connection link is one way" do
      before { connection_link.both_ways = false }
      it "returns 'Departure > Arrival'" do
        is_expected.to eq('Departure > Arrival')
      end
    end

    context "when the connection link is both ways" do
      before { connection_link.both_ways = true }
      it "returns 'Departure <> Arrival'" do
        is_expected.to eq('Departure <> Arrival')
      end
    end
  end
end
