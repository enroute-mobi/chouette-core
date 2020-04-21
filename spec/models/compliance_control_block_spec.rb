
RSpec.describe ComplianceControlBlock, type: :model do

  subject { build(:compliance_control_block) }

  it { should belong_to :compliance_control_set }
  it { should have_many(:compliance_controls).dependent(:destroy) }
  it { should validate_presence_of(:transport_mode) }

  it "validates that transport mode and submode are matching" do
    subject.transport_mode = "bus"
    subject.transport_submode = 'undefined'

    # BUS -> no submode = OK
    expect(subject).to be_valid

    # BUS -> bus specific submode = OK
    subject.transport_submode = "nightBus"
    expect(subject).to be_valid

    # BUS -> rail specific submode = KO
    subject.transport_submode = "regionalRail"
    expect(subject).not_to be_valid

    # RAIL -> rail specific submode = OK
    subject.transport_mode = "rail"
    expect(subject).to be_valid

    # RAILS -> no submode = KO
    subject.transport_submode = nil
    expect(subject).not_to be_valid
  end

  context "transport mode & submode uniqueness" do
    let(:cc_block) {create :compliance_control_block, transport_mode: 'bus', transport_submode: 'nightBus'}
    let(:cc_set1) { cc_block.compliance_control_set }
    let(:cc_set2) { create :compliance_control_set }

    it "sould be unique in a compliance control set" do
      expect( ComplianceControlBlock.new(block_kind: :transport_mode, transport_mode: 'bus', transport_submode: 'nightBus', compliance_control_set: cc_set1) ).not_to be_valid
      expect( ComplianceControlBlock.new(block_kind: :transport_mode, transport_mode: 'bus', transport_submode: 'nightBus', compliance_control_set: cc_set2) ).to be_valid
    end
  end
end
