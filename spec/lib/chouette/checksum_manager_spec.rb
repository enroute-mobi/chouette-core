# frozen_string_literal: true

RSpec.describe Af83::Decorator do
  let(:context) do
    Chouette.create do
      referential do
        route
      end
    end
  end
  let(:referential) { context.referential }
  let(:route) { context.route }

  before { referential&.switch }

  context "Chouette::ChecksumManager#current" do
    let(:referential) { nil }

    it "should return an Chouette::ChecksumManager::NoUpdates" do
      expect(Chouette::ChecksumManager.current).to be_a(Chouette::ChecksumManager::NoUpdates)
    end
  end

  context "Chouette::ChecksumManager#watch" do
    it "should delegate to the current manager" do
      expect(Chouette::ChecksumManager.current).to receive(:watch).with(route, from: nil).once
      Chouette::ChecksumManager.watch(route)
    end
  end

  context "#resolve_object" do
    it "should parse the params" do
      expect(Chouette::ChecksumManager::SerializedObject.new(route).object).to eq(route)
      expect(Chouette::ChecksumManager::SerializedObject.new(route).need_save).to be_falsy
      expect(Chouette::ChecksumManager::SerializedObject.new([route.class.name, route.id]).object).to eq(route)
      expect(Chouette::ChecksumManager::SerializedObject.new([route.class.name, route.id]).need_save).to be_truthy
    end
  end
end
