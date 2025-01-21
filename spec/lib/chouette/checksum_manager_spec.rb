RSpec.describe Af83::Decorator do
  context "Chouette::ChecksumManager#current" do
    it "should return an Chouette::ChecksumManager::NoUpdates" do
      expect(Chouette::ChecksumManager.current).to be_a(Chouette::ChecksumManager::NoUpdates)
    end
  end

  context "Chouette::ChecksumManager#watch" do
    it "should delegate to the current manager" do
      object = create(:route)
      expect(Chouette::ChecksumManager.current).to receive(:watch).with(object, from: nil).once
      Chouette::ChecksumManager.watch object
    end
  end

  context "#resolve_object" do
    it "should parse the params" do
      object = create(:route)
      expect(Chouette::ChecksumManager::SerializedObject.new(object).object).to eq(object)
      expect(Chouette::ChecksumManager::SerializedObject.new(object).need_save).to be_falsy
      expect(Chouette::ChecksumManager::SerializedObject.new([object.class.name, object.id]).object).to eq(object)
      expect(Chouette::ChecksumManager::SerializedObject.new([object.class.name, object.id]).need_save).to be_truthy
    end
  end
end
