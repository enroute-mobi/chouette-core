RSpec.describe Chouette::Sync::Base do

  subject(:sync) { Chouette::Sync::Test.new }

  class Chouette::Sync::Test < Chouette::Sync::Base

  end

  class Chouette::Sync::Test::Updater < Chouette::Sync::Updater

  end

  describe "#update_or_create" do

    let(:updater) { double }

    it "is delegated to Updater" do
      allow(sync).to receive(:updater).and_return(updater)
      expect(updater).to receive(:update)

      sync.update_or_create
    end

  end

  describe "#updater" do

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

    it "returns 'Test' for 'Chouette::Sync::Test' sync implementation" do
      expect(sync.model_class_name).to eq("Test")
    end

    it "returns 'StopArea' for 'Chouette::Sync::StopArea::Netex' sync implementation" do
      allow(sync).to receive(:class).and_return(double name: "Chouette::Sync::StopArea::Netex")
      expect(sync.model_class_name).to eq("StopArea")
    end

  end

  describe "#updater_class" do

    it "returns an updater class with this pattern: Chouette::Sync::<model_class_name>::Updater" do
      allow(sync).to receive(:model_class_name).and_return("Test")
      expect(sync.updater_class).to eq(Chouette::Sync::Test::Updater)
    end

  end

end
