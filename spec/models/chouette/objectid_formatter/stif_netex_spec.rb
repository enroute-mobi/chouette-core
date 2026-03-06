# frozen_string_literal: true

RSpec.describe Chouette::ObjectidFormatter::StifNetex do
  subject(:formatter) { described_class.new }

  let(:model) { Chouette::Route.new }

  describe '#before_validation' do
    subject { formatter.before_validation(model) }

    context 'when model has already an objectid' do
      before { model.objectid = 'dummy' }

      it { is_expected_to_not change(model, :raw_objectid) }
    end

    context 'when model has not primary key value' do
      before { model.id = nil }

      let(:pending_id) { 'pending_id' }
      before { allow(formatter).to receive(:pending_id).and_return(pending_id) }

      it { is_expected_to change(model, :raw_objectid).from(nil).to(pending_id) }
    end

    context 'when model has a primary key value' do
      before { model.id = 42 }

      let(:generated_id) { 'generated_id' }
      before { allow(formatter).to receive(:objectid).and_return(generated_id) }

      it { is_expected_to change(model, :raw_objectid).from(nil).to(generated_id) }
    end
  end

  describe '#after_commit' do
    subject { formatter.after_commit(model) }

    context 'when model is not persisted' do
      before { model.id = nil }

      it { is_expected_to_not change(model, :raw_objectid) }
    end

    context "when model haven't a pending objectid" do
      before { model.objectid = 'dummy' }

      it { is_expected_to_not change(model, :raw_objectid) }
    end

    context 'when objectid can be generated' do
      before do
        allow(model).to receive(:persisted?).and_return(true)
        model.id = 42
        model.objectid = '__pending_id__test'
      end

      before { allow(formatter).to receive(:objectid).and_return(generated_id) }

      let(:generated_id) do
        Chouette::Objectid::StifNetex.new(provider_id: 'test', object_type: 'type', local_id: 'local_id')
      end

      it do
        expect(model).to receive(:update_column).with(:objectid, generated_id.to_s)
        subject
      end
    end
  end

  describe '#objectid' do
    subject { formatter.objectid(model) }

    let(:generated_id) { 'generated_id' }

    it 'creates a Generator and returns generated objectid' do
      expect(Chouette::ObjectidFormatter::StifNetex::Generator).to receive(:for).with(model).and_return double(objectid: generated_id)
      is_expected.to eq(generated_id)
    end
  end

  describe Chouette::ObjectidFormatter::StifNetex::Generator::Base do
    subject(:generator) { described_class.new(model) }

    describe '#referential_id' do
      subject { generator.referential_id }

      context 'when model has a transient referential_id' do
        before { model.with_transient referential_id: 'transient_referential_id' }

        it { is_expected.to eq(model.transient(:referential_id)) }
      end

      context 'when model has no transient referential_id' do
        let(:referential) { double(id: 'referential id') }
        before { allow(model).to receive(:referential).and_return(referential) }

        it 'returns the Referential id' do
          is_expected.to eq(referential.id)
        end
      end
    end

    describe '#referential_prefix' do
      subject { generator.referential_prefix }

      context 'when model has a transient referential_prefix' do
        before { model.with_transient referential_prefix: 'transient_referential_prefix' }

        it { is_expected.to eq(model.transient(:referential_prefix)) }
      end

      context 'when model has no transient referential_prefix' do
        let(:referential) { double(prefix: 'referential prefix') }
        before { allow(model).to receive(:referential).and_return(referential) }

        it 'returns the Referential prefix' do
          is_expected.to eq(referential.prefix)
        end
      end
    end

    describe '#line_code' do
      subject { generator.line_code }

      context 'when model has a transient line_code' do
        before { model.with_transient line_code: 'transient_line_code' }

        it { is_expected.to eq(model.transient(:line_code)) }
      end

      context 'when model has no transient line_code' do
        let(:line) { double(get_objectid: double(local_id: 'line_local_id')) }
        before { allow(model).to receive(:line).and_return(line) }

        it 'returns the Line objectid local_id' do
          is_expected.to eq(line.get_objectid.local_id)
        end
      end
    end

    describe '#local_id_parts' do
      subject { generator.local_id_parts }

      context "when model id is 42, referential_id '<referential_id>' and line_code '<line_code>'" do
        before do
          model.id = 42
          allow(generator).to receive(:referential_id).and_return('<referential_id>')
          allow(generator).to receive(:line_code).and_return('<line_code>')
        end

        it { is_expected.to eq(['<referential_id>', '<line_code>', 42]) }
      end
    end

    describe '#local_id' do
      subject { generator.local_id }

      context 'when local_id_parts is [ 1, 2, 3 ]' do
        before do
          allow(generator).to receive(:local_id_parts).and_return([1, 2, 3])
        end

        it { is_expected.to eq('local-1-2-3') }
      end

      context 'when local_id_parts contains an undefined value' do
        before do
          allow(generator).to receive(:local_id_parts).and_return([1, nil, 3])
        end

        it { is_expected.to be_nil }
      end

      context 'when local_id_parts contains an blank value' do
        before do
          allow(generator).to receive(:local_id_parts).and_return([1, '', 3])
        end

        it { is_expected.to be_nil }
      end
    end

    describe '#object_type' do
      subject { generator.object_type }

      context 'model is Chouette::Route' do
        it { is_expected.to eq('Route') }
      end

      context 'model is Chouette::VehicleJourney' do
        let(:model) { Chouette::VehicleJourney.new }

        it { is_expected.to eq('VehicleJourney') }
      end
    end

    describe '#provider_id' do
      subject { generator.provider_id }

      context 'when referential_prefix is "dummy"' do
        before { allow(generator).to receive(:referential_prefix).and_return('dummy') }

        it { is_expected.to eq(generator.referential_prefix) }
      end
    end

    describe '#objectid' do
      subject { generator.objectid }

      before do
        allow(generator).to receive(:provider_id).and_return('test')
        allow(generator).to receive(:object_type).and_return('Route')
        allow(generator).to receive(:local_id).and_return('42')
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

      context 'when provider_id is "test", object_type "Route" and local_id "42"' do
        it { is_expected.to be_a(Chouette::Objectid::StifNetex) }

        it { is_expected.to have_attributes(provider_id: 'test', object_type: 'Route', local_id: '42') }
      end
    end
  end

  describe Chouette::ObjectidFormatter::StifNetex::Generator::StopPoint do
    subject(:generator) { described_class.new(model) }

    describe '#local_id' do
      subject { generator.local_id }
      context "when model id is 42, referential_id '<referential_id>', line_code '<line_code>' and route_id '<route_id>'" do
        before do
          model.id = 42
          allow(generator).to receive(:referential_id).and_return('<referential_id>')
          allow(generator).to receive(:line_code).and_return('<line_code>')
          allow(generator).to receive(:route_id).and_return('<route_id>')
        end

        it { is_expected.to eq('local-<referential_id>-<line_code>-<route_id>-42') }
      end
    end
  end

  describe Chouette::ObjectidFormatter::StifNetex::Generator::TimeTable do
    subject(:generator) { described_class.new(model) }

    describe '#local_id' do
      subject { generator.local_id }
      context "when model id is 42 and referential_id '<referential_id>'" do
        before do
          model.id = 42
          allow(generator).to receive(:referential_id).and_return('<referential_id>')
        end

        it { is_expected.to eq('local-<referential_id>-42') }
      end
    end
  end
end
