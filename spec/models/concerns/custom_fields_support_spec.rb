# frozen_string_literal: true

RSpec.describe CustomFieldsSupport do
  describe '.current_workgroup' do
    it 'is nil by default' do
      expect(described_class.current_workgroup).to be_nil
    end
  end

  describe 'within_workgroup' do
    let(:context) do
      Chouette.create do
        workgroup :workgroup1
        workgroup :workgroup2
      end
    end
    let(:workgroup1) { context.workgroup(:workgroup1) }
    let(:workgroup2) { context.workgroup(:workgroup2) }

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
end
