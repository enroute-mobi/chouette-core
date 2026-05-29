# frozen_string_literal: true

RSpec.describe Chouette::ObjectidFormatter::StifCodifligne do
  subject(:formatter) { described_class.new }

  let(:context) do
    Chouette.create do
      organisation :owner, code: 'OWNER'
      organisation :organisation, code: 'ORG1'
      workgroup owner: :owner do
        line_referential objectid_format: 'stif_codifligne'
        workbench  organisation: :organisation do
          line_provider
        end
      end
    end
  end

  let(:model) do
    context.line_provider.booking_arrangements.new(name: 'BA')
  end

  describe '#before_validation' do
    subject { formatter.before_validation(model) }

    context 'when model has already an objectid' do
      before { model.objectid = 'dummy' }

      it { is_expected_to_not change(model, :raw_objectid) }
    end

    context 'when model has no objectid' do
      let(:generated_id) { 'generated_id' }

      before { allow(formatter).to receive(:objectid).and_return(generated_id) }

      it { is_expected_to change(model, :raw_objectid).from(nil).to(generated_id) }
    end
  end

  describe '#after_commit' do
    subject { formatter.after_commit(model) }

    it { is_expected_to_not change(model, :raw_objectid) }
  end

  describe '#objectid' do
    subject { formatter.objectid(model) }

    let(:generated_id) { 'generated_id' }

    it 'creates a Generator and returns generated objectid' do
      expect(described_class::Generator).to receive(:for).with(model).and_return double(objectid: generated_id)
      is_expected.to eq(generated_id)
    end
  end

  describe Chouette::ObjectidFormatter::StifCodifligne::Generator::Base do
    subject(:generator) { described_class.new(model) }

    describe '#provider_id' do
      subject { generator.provider_id }

      it { is_expected.to eq('chouette') }
    end

    describe '#object_type' do
      subject { generator.object_type }

      context 'when model is BookingArrangement' do
        it { is_expected.to eq('BookingArrangement') }
      end
    end

    describe '#local_id' do
      subject { generator.local_id }

      it 'returns a random UUID' do
        is_expected.to match(/\b[0-9a-f]{8}\b-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-\b[0-9a-f]{12}\b/)
      end
    end

    describe '#local_marker' do
      subject { generator.local_marker }

      it { is_expected.to eq('LOC') }
    end

    describe '#objectid' do
      subject { generator.objectid }

      before do
        allow(generator).to receive(:provider_id).and_return('test')
        allow(generator).to receive(:object_type).and_return('BookingArrangement')
        allow(generator).to receive(:local_id).and_return('ad95bf6f-ef16-4a1a-ba39-346c954e44c0')
        allow(generator).to receive(:local_marker).and_return('LOC')
      end

      context 'when provider_id is nil' do
        before { allow(generator).to receive(:provider_id).and_return(nil) }

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

      context 'when local_marker is nil' do
        before { allow(generator).to receive(:local_marker).and_return(nil) }

        it { is_expected.to be_nil }
      end

      context 'when provider_id is "test", object_type "BookingArrangement", local_id "ad95bf6f-ef16-4a1a-ba39-346c954e44c0" and local_marker "LOC"' do
        it { is_expected.to be_a(Chouette::Objectid::StifCodifligne) }

        it do
          is_expected.to have_attributes(
            provider_id: 'test',
            object_type: 'BookingArrangement',
            local_id: 'ad95bf6f-ef16-4a1a-ba39-346c954e44c0',
            local_marker: 'LOC'
          )
        end
      end
    end
  end

  describe Chouette::ObjectidFormatter::StifCodifligne::Generator::BookingArrangement do
    subject(:generator) { Chouette::ObjectidFormatter::StifCodifligne::Generator.for(model) }

    it { is_expected.to be_a(described_class) }

    describe '#provider_id' do
      subject { generator.provider_id }

      it { is_expected.to eq('ORG1') }
    end
  end
end
