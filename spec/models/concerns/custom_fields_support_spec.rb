# frozen_string_literal: true

RSpec.describe CustomFieldsSupport do
  describe '.current_workgroup' do
    it 'is nil by default' do
      expect(described_class.current_workgroup).to be_nil
    end
  end

  describe 'within_workgroup' do
    let(:workgroup1) { Workgroup.new }
    let(:workgroup2) { Workgroup.new }

    let(:current_workgroups) { [] }

    it 'sets current workgroup' do
      described_class.within_workgroup(workgroup1) do
        current_workgroups << described_class.current_workgroup
      end
      expect(current_workgroups).to eq([workgroup1])
    end

    it 'accepts nested blocks' do
      described_class.within_workgroup(workgroup1) do
        current_workgroups << described_class.current_workgroup
        described_class.within_workgroup(workgroup1) do
          current_workgroups << described_class.current_workgroup
        end
        current_workgroups << described_class.current_workgroup
      end
      expect(current_workgroups).to eq([workgroup1, workgroup1, workgroup1])
    end

    it 'crashes with nested blocks with different workgroups' do
      expect do
        described_class.within_workgroup(workgroup1) do
          described_class.within_workgroup(workgroup2) {}
        end
      end.to raise_error(RuntimeError, /Two different current workgroups/)
    end

    it 'accepts nil' do
      described_class.within_workgroup(nil) do
        current_workgroups << described_class.current_workgroup
      end
      expect(current_workgroups).to eq([nil])
    end
  end

  describe '#skip_custom_fields_initialization' do
    # with_model doesn't work with #around :(
    let(:model_class) { Chouette::StopArea }
    let(:model) { model_class.new }

    subject { model.skip_custom_fields_initialization }

    context 'when instance skip_custom_fields_initialization is set' do
      let(:model) { model_class.new(skip_custom_fields_initialization: true) }

      it { is_expected.to be_truthy }
    end

    context 'when Class skip_custom_fields_initialization is set' do
      # with_model doesn't work with #around :(
      around(:example) do |example|
        model_class.without_custom_fields do
          example.run
        end
      end

      it { is_expected.to be_truthy }
    end
  end
end
