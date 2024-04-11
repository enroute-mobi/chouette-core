# frozen_string_literal: true

RSpec.describe Code do
  let(:context) do
    Chouette.create do
      workgroup do
        stop_area
      end
    end
  end

  let(:workgroup) { context.workgroup }
  let(:code_space) { workgroup.code_spaces.create short_name: 'test' }
  let(:resource) { context.stop_area }

  describe 'validation' do
    def code(attributes = {})
      attributes.reverse_merge! value: 'dummy', resource: resource, code_space: code_space
      Code.new attributes
    end

    it 'validates value presence' do
      expect(code(value: nil)).to_not be_valid
      expect(code(value: 'dummy')).to be_valid
    end

    it 'validates resource presence' do
      expect(code(resource: nil)).to_not be_valid
      expect(code(resource: resource)).to be_valid
    end

    it 'validates code_space presence' do
      expect(code(code_space: nil)).to_not be_valid
      expect(code(code_space: code_space)).to be_valid
    end
  end

  describe Code::Value do
    describe '.parse' do
      subject { Code::Value.parse value }

      context 'with ""' do
        let(:value) { '' }

        it { is_expected.to be_nil }
      end

      context 'with "chouette:JourneyPattern:1:LOC"' do
        let(:value) { 'chouette:JourneyPattern:1:LOC' }

        it { is_expected.to eq(Netex::ObjectId.parse(value)) }
      end

      context 'with "1"' do
        let(:value) { '1' }

        it { is_expected.to eq(Code::Value.new(value)) }
      end

      context 'with "7bb7764a-e6c1-11ee-8215-77369735fc1a"' do
        let(:value) { '7bb7764a-e6c1-11ee-8215-77369735fc1a' }

        it { is_expected.to eq(Code::Value.new(value)) }
      end
    end

    describe '#change' do
      subject { value.change(type: type) }

      context 'when value is "1"' do
        let(:value) { Code::Value.new('1') }

        context 'with type "Example"' do
          let(:type) { 'Example' }

          it { is_expected.to eq('Example:1') }
        end
      end
    end

    describe '#merge' do
      subject { value.merge(other, type: type) }

      context 'when value is "1"' do
        let(:value) { Code::Value.new('1') }

        context 'with other "dummy" and type "Example"' do
          let(:other) { 'dummy' }
          let(:type) { 'Example' }

          it { is_expected.to eq('Example:1-dummy') }
        end
      end
    end

    describe '.merge' do
      subject { Code::Value.merge(value, other, type: type) }

      context 'when value is "1"' do
        let(:value) { Code::Value.new('1') }

        context 'with other "dummy" and type "Example"' do
          let(:other) { 'dummy' }
          let(:type) { 'Example' }

          it { is_expected.to eq('Example:1-dummy') }
        end
      end

      context 'when value is "chouette:JourneyPattern:1:LOC"' do
        let(:value) { Code::Value.parse('chouette:JourneyPattern:1:LOC') }

        context 'with other "dummy" and type "Example"' do
          let(:other) { 'dummy' }
          let(:type) { 'Example' }

          it { is_expected.to eq(Netex::ObjectId.parse('chouette:Example:1-dummy:LOC')) }
        end
      end
    end
  end
end
