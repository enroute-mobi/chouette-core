RSpec.describe ComplianceCheck, type: :model do

  it 'should have a valid factory' do
    expect(FactoryGirl.build(:compliance_check)).to be_valid
  end

  it 'should rely on IEV by default' do
    expect(FactoryGirl.build(:compliance_check).iev_enabled_check).to be_truthy
  end

  it 'has STI disabled' do
    expect( described_class.inheritance_column ).to be_blank
  end

  it { should belong_to :compliance_check_set }
  it { should belong_to :compliance_check_block }

  it { should validate_presence_of :criticity }
  it { should validate_presence_of :name }
  it { should validate_presence_of :code }
  it { should validate_presence_of :origin_code }

  describe ".abort_old" do
    it "changes check sets older than 4 hours to aborted" do
      Timecop.freeze(Time.now) do
        old_check_set = create(
          :compliance_check_set,
          status: 'pending',
          created_at: 4.hours.ago - 1.minute
        )
        current_check_set = create(:compliance_check_set, status: 'pending')

        ComplianceCheckSet.abort_old

        expect(current_check_set.reload.status).to eq('pending')
        expect(old_check_set.reload.status).to eq('aborted')
      end
    end

    it "doesn't work on check sets with a `finished_status`" do
      Timecop.freeze(Time.now) do
        check_set = create(
          :compliance_check_set,
          status: 'successful',
          created_at: 4.hours.ago - 1.minute
        )

        ComplianceCheckSet.abort_old

        expect(check_set.reload.status).to eq('successful')
      end
    end
  end
end
