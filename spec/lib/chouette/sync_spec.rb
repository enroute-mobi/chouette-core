RSpec.describe Chouette::Sync::Base do

  subject(:sync) { Chouette::Sync::Test.new }

  class Chouette::Sync::Test < Chouette::Sync::Base

  end

  class Chouette::Sync::Test::Updater < Chouette::Sync::Updater

  end

  class Chouette::Sync::Test::Deleter < Chouette::Sync::Deleter

  end

  describe "#update_or_create" do

    let(:updater) { double }

    it "is delegated to Updater" do
      allow(sync).to receive(:updater).and_return(updater)
      expect(updater).to receive(:update_or_create)

      sync.update_or_create
    end

  end

  describe "#delete" do

    let(:deleter) { double }
    let(:resource_identifiers) { [1,2,3] }

    it "is delegated to Deleter" do
      allow(sync).to receive(:deleter).and_return(deleter)
      expect(deleter).to receive(:delete).with(resource_identifiers)

      sync.delete(resource_identifiers)
    end

  end

  describe "#updater" do

    before do
      described_class.send(:public, :updater)
    end

    it "is a Chouette::Sync::Test::Updater instance in test context" do
      expect(sync.updater).to be_a(Chouette::Sync::Test::Updater)
    end

    it "uses the same source than the Sync" do
      sync.source = double
      expect(sync.updater.source).to eq(sync.source)
    end

    it "uses the same target than the Sync" do
      sync.target = double
      expect(sync.updater.target).to eq(sync.target)
    end

  end

  describe "#model_class_name" do

    before do
      described_class.send(:public, :model_class_name)
    end

    it "returns 'Test' for 'Chouette::Sync::Test' sync implementation" do
      expect(sync.model_class_name).to eq("Test")
    end

    it "returns 'StopArea' for 'Chouette::Sync::StopArea::Netex' sync implementation" do
      allow(sync).to receive(:class).and_return(double name: "Chouette::Sync::StopArea::Netex")
      expect(sync.model_class_name).to eq("StopArea")
    end

  end

  describe "#updater_class" do

    before do
      described_class.send(:public, :updater_class)
    end

    it "returns an updater class with this pattern: Chouette::Sync::<model_class_name>::Updater" do
      allow(sync).to receive(:model_class_name).and_return("Test")
      expect(sync.updater_class).to eq(Chouette::Sync::Test::Updater)
    end

  end

  describe "#deleter_class" do

    before do
      described_class.send(:public, :deleter_class)
    end

    it "returns an deleter class with this pattern: Chouette::Sync::<model_class_name>::Deleter" do
      allow(sync).to receive(:model_class_name).and_return("Test")
      expect(sync.deleter_class).to eq(Chouette::Sync::Test::Deleter)
    end

  end

  describe "#deleter" do

    before do
      described_class.send(:public, :deleter)
    end

    it "is a Chouette::Sync::Test::Deleter instance in test context" do
      expect(sync.deleter).to be_a(Chouette::Sync::Test::Deleter)
    end

    it "uses the same target than the Sync" do
      sync.target = double
      expect(sync.deleter.target).to eq(sync.target)
    end

  end

end
