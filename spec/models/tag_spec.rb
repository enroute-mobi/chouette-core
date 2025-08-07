RSpec.describe Tag do
  let(:context) do
    Chouette.create do
      workbench
    end
  end
  let(:workbench) { context.workbench }

  let(:tag) { Tag.new workbench: workbench, name: 'Test tag' }

  describe '.table_name' do
    subject { described_class.table_name }
    it { is_expected.to eq('public.tags') }
  end
end