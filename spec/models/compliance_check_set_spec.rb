require 'rails_helper'

RSpec.describe ComplianceCheckSet, type: :model do
  it 'should have a valid factory' do
    expect(FactoryGirl.build(:compliance_check_set)).to be_valid
  end

  it { should belong_to :referential }
  it { should belong_to :workbench }
  it { should belong_to :compliance_control_set }
  it { should belong_to :parent }

  it { should have_many :compliance_checks }
  it { should have_many :compliance_check_blocks }

  describe "#update_status" do
    it "updates :status to successful when all resources are OK" do
      check_set = create(:compliance_check_set)
      create_list(
        :compliance_check_resource,
        2,
        compliance_check_set: check_set,
        status: 'OK'
      )

      check_set.update_status

      expect(check_set.status).to eq('successful')
    end
  end
end
