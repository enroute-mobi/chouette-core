# frozen_string_literal: true

RSpec.describe Export::CodeProvider do
  subject(:code_provider) { Export::CodeProvider.new(export_scope) }
  let(:export_scope) { double }

  describe '#code' do
    subject { code_provider.code(value) }

    context 'when given value is nil' do
      let(:value) { nil }

      it { is_expected.to be_nil }
    end

    context 'when the given StopArea 1 has been indexed with "dummy"' do
      let(:value) { Chouette::StopArea.new(id: 1) }
      before { allow(code_provider).to receive(:stop_areas).and_return(double(code: 'dummy')) }

      it { is_expected.to eq('dummy') }
    end
  end

  describe '#stop_areas' do
    subject { code_provider.stop_areas }

    before { allow(export_scope).to receive(:stop_areas).and_return(Chouette::StopArea.none) }

    it { is_expected.to have_attributes(collection: export_scope.stop_areas) }
  end

  describe '#lines' do
    subject { code_provider.lines }

    before { allow(export_scope).to receive(:lines).and_return(Chouette::Line.none) }

    it { is_expected.to have_attributes(collection: export_scope.lines) }
  end

  describe Export::CodeProvider::Model::Index do
    context 'when model class is Chouette::StopArea' do
      subject(:model_code_provider) { described_class.new Chouette::StopArea.none }

      describe '#attribute' do
        subject { model_code_provider.attribute }

        it { is_expected.to eq('objectid') }
      end

      describe '#codes' do
        subject { described_class.new(Chouette::StopArea.all, code_space).codes }

        let(:context) do
          Chouette.create do
            code_space short_name: 'test'
            code_space :other, short_name: 'other'

            stop_area :first, codes: { test: 'first code' }
            stop_area :second, codes: { test: 'second code', other: 'other second code' }
            stop_area :third, objectid: 'third objectid', codes: { other: 'other third code' }
            stop_area :last, objectid: 'last objectid'
          end
        end

        let(:code_space) { context.code_space }
        let(:first) { context.stop_area(:first) }
        let(:second) { context.stop_area(:second) }
        let(:third) { context.stop_area(:third) }
        let(:last) { context.stop_area(:last) }

        it do
          expected_codes = {
            first.id => 'first code',
            second.id => 'second code',
            third.id => 'third objectid:::LOC',
            last.id => 'last objectid:::LOC'
          }

          is_expected.to eq expected_codes
        end

        context 'when there are many codes in the same Code Space' do
          before { first.codes.create(code_space: code_space, value: 'first code 2') }

          it 'should not use codes and take objectid for the first stop area' do

            expect(subject[first.id]).to eq first.objectid
          end
        end
      end
    end

    context 'when model class is PointOfInterest' do
      # TODO

      describe '#attribute' do
        # TODO

        xit { is_expected.to eq('uuid') }
      end

      # TODO
    end
  end

  describe Export::CodeProvider::Null do
    subject(:code_provider) { Export::CodeProvider.null }

    describe '#code' do
      subject { code_provider.code(value) }

      context 'when given value is nil' do
        let(:value) { nil }

        it { is_expected.to be_nil }
      end

      context 'when a StopArea 1 is given' do
        let(:value) { Chouette::StopArea.new(id: 1) }

        it { is_expected.to be_nil }
      end
    end

    describe '#stop_areas' do
      subject(:stop_areas) { code_provider.stop_areas }

      describe '#code' do
        subject { stop_areas.code(value) }

        context 'when given value is nil' do
          let(:value) { nil }

          it { is_expected.to be_nil }
        end

        context 'when 1 is given' do
          let(:value) { 1 }

          it { is_expected.to be_nil }
        end
      end
    end
  end
end
