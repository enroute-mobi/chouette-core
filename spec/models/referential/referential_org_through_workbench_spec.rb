RSpec.describe Referential do
  describe 'Normalisation between Workbench and Organisation' do
    let(:workgroup) { create(:workgroup) }
    let(:workbench) { create(:workbench) }

    context 'no workbench nor workgroup' do
      subject { build(:referential, organisation: nil, workbench: nil) }

      it do
        expect_it.not_to be_valid
      end
    end

    context 'no workbench but workgroup' do
      subject { build(:referential, organisation: nil, referential_suite: workgroup.output) }

      it do
        expect_it.to be_valid
      end
    end

    context 'workbench without workgroup' do
      subject { build(:referential, organisation: nil, workbench: workbench) }

      it do
        expect_it.to be_valid
      end
    end

    context 'workbench and workgroup' do
      subject { build(:referential, organisation: nil, workbench: workbench, referential_suite: workgroup.output) }

      it do
        expect_it.to be_valid
      end
    end
  end
end
