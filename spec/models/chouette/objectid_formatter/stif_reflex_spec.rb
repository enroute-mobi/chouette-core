# frozen_string_literal: true

RSpec.describe Chouette::ObjectidFormatter::StifReflex do
  subject(:formatter) { described_class.new }

  let(:context) do
    Chouette.create do
      workgroup do
        stop_area_referential objectid_format: 'stif_reflex'
        workbench
      end
    end
  end

  let(:stop_area_type) { Chouette::AreaType::FLEXIBLE_STOP_PLACE }
  let(:model) { context.workbench.stop_areas.new(name: 'BA', area_type: stop_area_type) }

  describe '#before_validation' do
    subject { formatter.before_validation(model) }

    context 'when model has already an objectid' do
      before { model.objectid = 'dummy' }

      it { is_expected_to_not change(model, :raw_objectid) }
    end

    context 'when model has not primary key value' do
      let(:pending_id) { 'pending_id' }

      before { allow(formatter).to receive(:pending_id).and_return(pending_id) }

      it { is_expected_to change(model, :raw_objectid).from(nil).to(pending_id) }
    end

    context 'when model has a primary key value' do
      let(:generated_id) { 'generated_id' }

      before do
        model.id = 42
        allow(formatter).to receive(:objectid).and_return(generated_id)
      end

      it { is_expected_to change(model, :raw_objectid).from(nil).to(generated_id) }
    end
  end

  describe '#after_commit' do
    subject { formatter.after_commit(model) }

    let(:persisted) { true }
    let(:objectid) { '__pending_id__test' }

    before do
      allow(model).to receive(:persisted?).and_return(persisted)
      model.id = 42
      model.objectid = objectid
    end

    context 'when model is not persisted' do
      let(:persisted) { false }

      it { is_expected_to_not change(model, :raw_objectid) }
    end

    context 'when model is persisted' do
      context 'when model has not a pending objectid' do
        before { model.objectid = 'dummy' }

        it { is_expected_to_not change(model, :raw_objectid) }
      end

      context 'when model has a pending objectid' do
        before { allow(formatter).to receive(:objectid).and_return(generated_id) }

        let(:generated_id) do
          Chouette::Objectid::StifReflex.new(provider_id: 'test', object_type: 'type', local_id: '42')
        end

        it do
          expect(model).to receive(:update_column).with(:objectid, generated_id.to_s)
          subject
        end
      end
    end
  end

  describe '#objectid' do
    subject { formatter.objectid(model) }

    let(:generated_id) { 'generated_id' }

    it 'creates a Generator and returns generated objectid' do
      expect(described_class::Generator).to receive(:for).with(model).and_return double(objectid: generated_id)
      is_expected.to eq(generated_id)
    end
  end

  describe Chouette::ObjectidFormatter::StifReflex::Generator do
    describe '.for' do
      subject { described_class.for(model) }

      context 'with a StopArea' do
        context 'when StopArea is a quay' do
          let(:stop_area_type) { Chouette::AreaType::QUAY }

          it { is_expected.to be_a(Chouette::ObjectidFormatter::StifReflex::Generator::Base) }
        end

        context 'when StopArea is a flexible stop area' do
          it { is_expected.to be_a(Chouette::ObjectidFormatter::StifReflex::Generator::FlexibleStopPlace) }
        end
      end
    end
  end

  describe Chouette::ObjectidFormatter::StifReflex::Generator::Base do
    subject(:generator) { described_class.new(model) }

    describe '#country_code' do
      subject { generator.country_code }

      it { is_expected.to eq('FR') }
    end

    describe '#object_type' do
      subject { generator.object_type }

      context 'when model is Chouette::StopArea' do
        it { is_expected.to eq('StopArea') }
      end
    end

    describe '#local_id' do
      subject { generator.local_id }

      before { model.id = 42 }

      it 'returns the id as a string' do
        is_expected.to eq('42')
      end
    end

    describe '#provider_id' do
      subject { generator.provider_id }

      it { is_expected.to eq('FR1') }
    end

    describe '#objectid' do
      subject { generator.objectid }

      before do
        allow(generator).to receive(:country_code).and_return('EN')
        allow(generator).to receive(:object_type).and_return('StopArea')
        allow(generator).to receive(:local_id).and_return('42')
        allow(generator).to receive(:provider_id).and_return('FR1')
      end

      context 'when country_code is nil' do
        before { allow(generator).to receive(:country_code).and_return(nil) }

        it { is_expected.to be_nil }
      end

      context 'when object_type is nil' do
        before { allow(generator).to receive(:object_type).and_return(nil) }

        it { is_expected.to be_nil }
      end

      context 'when local_id is nil' do
        before { allow(generator).to receive(:local_id).and_return(nil) }

        it { is_expected.to be_nil }
      end

      context 'when provider_id is nil' do
        before { allow(generator).to receive(:provider_id).and_return(nil) }

        it { is_expected.to be_nil }
      end

      context 'when country_code is "EN", object_type "StopArea", local_id "42" and provider_id "FR1"' do
        it { is_expected.to be_a(Chouette::Objectid::StifReflex) }

        it do
          is_expected.to have_attributes(
            country_code: 'EN',
            object_type: 'StopArea',
            local_id: '42',
            provider_id: 'FR1'
          )
        end
      end
    end
  end

  describe Chouette::ObjectidFormatter::StifReflex::Generator::FlexibleStopPlace do
    subject(:generator) { Chouette::ObjectidFormatter::StifReflex::Generator.for(model) }

    describe '#object_type' do
      subject { generator.object_type }

      it { is_expected.to eq('FlexibleStopPlace') }
    end
  end
end
