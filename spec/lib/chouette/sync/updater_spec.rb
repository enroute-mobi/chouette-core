# frozen_string_literal: true

RSpec.describe Chouette::Sync::Updater do
  subject(:updater) { Test.new }

  class Test < Chouette::Sync::Updater
  end

  let(:context) do
    Chouette.create do
      stop_area_provider
    end
  end

  let(:target) { context.stop_area_provider }

  def resource(id)
    double "Resource #{id}", id: id, name: "Name #{id}"
  end

  def resources(*identifiers)
    identifiers.map { |id| resource id }
  end

  describe '#resources' do
    it 'uses resources provided by source according to resource_type' do
      source = double(items: double)
      updater.source = source
      updater.resource_type = :item

      expect(updater.resources).to eq(source.items)
    end
  end

  describe '#resources_in_batches' do
    it 'invokes the given block with a Batch for each resource slice (controled by update_batch_size)' do
      updater.update_batch_size = 1
      updater.resource_id_attribute = :id

      all_resources = resources(1, 2, 3)
      allow(updater).to receive(:resources).and_return(all_resources)

      batched_resources = []
      updater.resources_in_batches do |batch|
        batched_resources.concat batch.resources
      end
      expect(batched_resources).to eq(all_resources)
    end
  end

  describe Chouette::Sync::Updater::Batch do
    def create_batch(resources = nil, updater: nil)
      resources ||= self.resources(1, 2, 3)
      updater ||= double resource_id_attribute: :id
      Chouette::Sync::Updater::Batch.new resources, updater: updater
    end

    describe '#resource_id_attribute' do
      let(:updater) { double resource_id_attribute: :dummy }

      it 'uses resource_id_attribute provided by Updater' do
        batch = create_batch updater: updater
        expect(batch.resource_id_attribute).to eq(updater.resource_id_attribute)
      end
    end

    describe '#resource_ids' do
      let(:expected_identifiers) { (1..3).to_a }

      it 'returns the identifiers of Batch resources (as string)' do
        batch = create_batch resources(*expected_identifiers)
        expect(batch.resource_ids).to match_array(expected_identifiers.map(&:to_s))
      end
    end

    describe '#models' do
      let(:updater) { double models: double }

      it 'returns the identifiers of Batch resources' do
        batch = create_batch updater: updater
        expect(batch.models).to eq(updater.models)
      end
    end
  end

  describe 'with real target' do
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

    context 'when the source provides a new Model' do
      before { source.resources << resource(1) }

      it 'creates the associated Model' do
        expect { updater.update_or_create }.to change { target.stop_areas.count }.by(1)
      end

      describe 'emitted events' do
        subject(:events) { [] }

        before do
          updater.event_handler = Chouette::Sync::Event::Handler.new { |event| events << event }
          updater.update_or_create
        end

        it do
          is_expected.to include(
            an_object_having_attributes(
              type: 'create',
              resource: source.resources.first,
              model: target.stop_areas.first,
              count: 1,
              errors: {}
            )
          )
        end
      end
    end

    context 'when the source provides several new Models' do
      let(:resource_count) { 10 }
      before { resource_count.times { |n| source.resources << resource(n) } }

      it 'creates the associated Model' do
        expect { updater.update_or_create }.to change { target.stop_areas.count }.by(resource_count)
      end

      it 'sends events with created model counts' do
        create_count = 0
        updater.event_handler = Chouette::Sync::Event::Handler.new { |event| create_count += event.count }
        expect { updater.update_or_create }.to change { create_count }.by(resource_count)
      end
    end

    context 'when the source provides an existing Model' do
      let!(:existing_model) do
        target.stop_areas.create! name: 'Old name', registration_number: 'test'
      end

      let(:source_resource) { resource('test') }
      before { source.resources << source_resource }

      it 'updates the associated StopArea' do
        expect { updater.update_or_create }.to change { existing_model.reload.name }.to(source_resource.name)
      end

      describe 'emitted events' do
        subject(:events) { [] }

        before do
          updater.event_handler = Chouette::Sync::Event::Handler.new { |event| events << event }
          updater.update_or_create
        end

        it do
          is_expected.to include(
            an_object_having_attributes(
              type: 'update',
              resource: source.resources.first,
              model: target.stop_areas.first,
              count: 1,
              errors: {}
            )
          )
        end
      end
    end

    context 'when the source provides several existing Models' do
      let(:resource_count) { 10 }
      let(:old_name) { 'Old name' }

      before do
        resource_count.times do |n|
          source.resources << resource(n)
          target.stop_areas.create! name: old_name, registration_number: n
        end
      end

      it 'updates the associated StopArea' do
        expect { updater.update_or_create }.to change {
          target.stop_areas.where(name: old_name).count
        }.from(resource_count).to(0)
      end

      it 'sends events with updated model counts' do
        update_count = 0
        updater.event_handler = Chouette::Sync::Event::Handler.new { |event| update_count += event.count }
        expect { updater.update_or_create }.to change { update_count }.by(resource_count)
      end
    end
  end

  describe Chouette::Sync::Updater::Provider do
    let(:context) { Chouette.create { workbench } }
    let(:workbench) { context.workbench }
    let(:workgroup) { context.workgroup }
    let(:target) { workbench.stop_area_referential }
    let(:default_provider) { workbench.default_stop_area_provider }
    let!(:provider) { Chouette::Sync::Updater::Provider.new target, default_provider }

    describe '#scope' do
      subject { provider.scope }
      it { is_expected.to eq(target.stop_area_providers) }
    end

    describe '#target_is_provider?' do
      subject { provider.target_is_provider? }
      it { is_expected.to eq(false) }
    end
  end
end

RSpec.describe Chouette::Sync::Updater::Models do
  subject(:models) { Chouette::Sync::Updater::Models.new(scope) }
  let(:scope) { double }

  describe '#prepare_attributes' do
    subject { models.prepare_attributes(resource) }

    let(:resource) { double id: 42, model_attributes: model_attributes }
    let(:model_attributes) { {} }

    before { allow(models).to receive(:model_id_attribute).and_return(:registration_number) }

    [nil, '', []].each do |empty_value|
      context "when model attributes contains dummy: #{empty_value.inspect}" do
        before { model_attributes[:dummy] = empty_value }

        context 'when strict mode is disabled' do
          before { allow(models).to receive(:strict_mode?).and_return(false) }

          it { is_expected.to_not have_key(:dummy) }
        end

        context 'when strict mode is enabled' do
          before { allow(models).to receive(:strict_mode?).and_return(true) }

          it { is_expected.to have_key(:dummy) }
        end
      end
    end
  end
end
