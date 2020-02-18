RSpec.describe WebhookEvent do
  alias_method :event, :subject

  it { is_expected.to validate_inclusion_of(:type).in_array(%w(created updated destroyed)) }

  describe "attributes loading" do

    it "uses type attribute in json" do
      event.attributes = { type: "created" }
      expect(event.type).to eq("created")
    end

  end

  describe "created/update event" do

    before do
      event.type = "created"
    end

    it "accepts only payload in resources" do
      event.resources[:test] = "payload"
      expect(event).to be_valid
    end

    it "refuses attributes in resources" do
      event.resources[:test] = { id: "wrong" }
      expect(event).to_not be_valid
      expect(event.errors).to include(:test)
    end

  end

  describe "destroyed event" do

    before do
      event.type = "destroyed"
    end

    it "accepts only id attribute in resources" do
      event.resources[:test] = { id: "42" }
      expect(event).to be_valid
    end

    it "refuses attributes without id in resources" do
      event.resources[:test] = { name: "wrong" }
      expect(event).to_not be_valid
      expect(event.errors).to include(:test)
    end

    it "refuses payload in resources" do
      event.resources[:test] = "payload"
      expect(event).to_not be_valid
      expect(event.errors).to include(:test)
    end

  end

  describe WebhookEvent::StopAreaReferential do

    describe "attributes loading" do

      let(:payload) { "payload" }

      %w{stop_place stop_places quay quays}.each do |resource_name|
        it "uses #{resource_name} attribute in json" do
          event.attributes = { resource_name => payload }
          expect(event.send(resource_name)).to eq(payload)
        end
      end

    end

  end

  describe WebhookEvent::LineReferential do

    describe "attributes loading" do

      let(:payload) { "payload" }

      %w{line lines operator operators network networks}.each do |resource_name|
        it "uses #{resource_name} attribute in json" do
          event.attributes = { resource_name => payload }
          expect(event.send(resource_name)).to eq(payload)
        end
      end

    end

  end

end
