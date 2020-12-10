RSpec.describe Chouette::Sync::Updater do

  subject(:updater) { Test.new  }

  class Test < Chouette::Sync::Updater

  end

  let(:context) do
    Chouette.create do
      stop_area_provider
    end
  end

  let(:target) { context.stop_area_provider }

  def resource(id)
    double id: id, name: "Name #{id}"
  end

  def resources(*identifiers)
    identifiers.map { |id| resource id }
  end

  describe "#resources" do

    it "uses resources provided by source according to resource_type" do
      source = double(items: double)
      updater.source = source
      updater.resource_type = :item

      expect(updater.resources).to eq(source.items)
    end

  end

  describe "#resources_in_batches" do

    it "invokes the given block with a Batch for each resource slice (controled by update_batch_size)" do
      updater.update_batch_size = 1
      updater.resource_id_attribute = :id

      all_resources = resources(1,2,3)
      allow(updater).to receive(:resources).and_return(all_resources)

      batched_resources = []
      updater.resources_in_batches do |batch|
        batched_resources.concat batch.resources
      end
      expect(batched_resources).to eq(all_resources)
    end

  end

  describe "#report_invalid_model" do

    let(:model) { double errors: [] }

    it "increments the errors counter" do
      expect { updater.report_invalid_model(model) }.to change { updater.counters.errors }.by(1)
    end

  end

  describe Chouette::Sync::Updater::Batch do

    def create_batch(resources = nil, updater: nil)
      resources ||= self.resources(1,2,3)
      updater ||= double resource_id_attribute: :id
      Chouette::Sync::Updater::Batch.new resources, updater: updater
    end

    describe "#resource_id_attribute" do

      let(:updater) { double resource_id_attribute: :dummy }

      it "uses resource_id_attribute provided by Updater" do
        batch = create_batch updater: updater
        expect(batch.resource_id_attribute).to eq(updater.resource_id_attribute)
      end

    end

    describe "#resource_ids" do

      let(:expected_identifiers) { (1..3).to_a }

      it "returns the identifiers of Batch resources (as string)" do
        batch = create_batch resources(*expected_identifiers)
        expect(batch.resource_ids).to match_array(expected_identifiers.map(&:to_s))
      end

    end

    describe "#models" do

      let(:updater) { double models: double }

      it "returns the identifiers of Batch resources" do
        batch = create_batch updater: updater
        expect(batch.models).to eq(updater.models)
      end

    end

  end

  describe "with real target" do


    let(:source) { double resources: [] }

    class TestDecorator < Chouette::Sync::Updater::ResourceDecorator

      def model_attributes
        {
          name: name
        }
      end

    end

    let(:updater) do
      Chouette::Sync::Updater.new source: source, target: target, update_batch_size: 3,
                                  resource_type: :resource, resource_id_attribute: :id,
                                  resource_decorator: TestDecorator,
                                  model_type: :stop_area, model_id_attribute: :registration_number
    end

    context "when the source provides a new Model" do

      before { source.resources << resource(1) }

      it "creates the associated Model" do
        expect { updater.update_or_create }.to change { target.stop_areas.count }.by(1)
      end

      it "increments the create_count" do
        expect { updater.update_or_create }.to change{ updater.counters.create }.by(1)
      end

    end

    context "when the source provides several new Models" do

      let(:resource_count) { 10 }
      before { resource_count.times { |n| source.resources << resource(n) } }

      it "creates the associated Model" do
        expect { updater.update_or_create }.to change { target.stop_areas.count }.by(resource_count)
      end

      it "increments the :create count" do
        expect { updater.update_or_create }.to change{ updater.counters.create }.by(resource_count)
      end

    end

    context "when the source provides an existing Model" do

      let!(:existing_model) do
        target.stop_areas.create! name: "Old name", registration_number: "test"
      end

      let(:source_resource) { resource("test") }
      before { source.resources << source_resource }

      it "updates the associated StopArea" do
        expect { updater.update_or_create }.to change { existing_model.reload.name }.to(source_resource.name)
      end

      it "increments the :update count" do
        expect { updater.update_or_create }.to change{ updater.counters.update }.by(1)
      end

    end

    context "when the source provides several existing Models" do

      let(:resource_count) { 10 }
      let(:old_name) { "Old name" }

      before do
        resource_count.times do |n|
          source.resources << resource(n)
          target.stop_areas.create! name: old_name, registration_number: n
        end
      end

      it "updates the associated StopArea" do
        expect { updater.update_or_create }.to change {
          target.stop_areas.where(name: old_name).count
        }.from(resource_count).to(0)
      end

      it "increments the update count" do
        expect { updater.update_or_create }.to change{
          updater.counters.update
        }.by(resource_count)
      end

    end

  end

end
