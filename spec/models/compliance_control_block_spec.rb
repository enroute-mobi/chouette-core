require 'rails_helper'

RSpec.describe ComplianceControlBlock, type: :model do

  it { should belong_to :compliance_control_set }
  it { should have_many(:compliance_controls).dependent(:destroy) }
  it { should validate_presence_of(:transport_mode) }

  it { should allow_values(*%w{bus metro rail tram funicular}).for(:transport_mode) }
  it { should_not allow_values(*%w{bs mtro ril tramm Funicular}).for(:transport_mode) }


  it { should allow_values( *%w{ demandAndResponseBus nightBus airportLinkBus highFrequencyBus expressBus
                                 railShuttle suburbanRailway regionalRail interregionalRail })
        .for(:transport_submode) }

  it { should_not allow_values( *%w{ demandResponseBus nightus irportLinkBus highrequencyBus expressBUs
                                     Shuttle suburban regioalRail interregion4lRail })
        .for(:transport_submode) }

  context "transport mode & submode uniqueness" do
    let(:cc_block) {create :compliance_control_block, transport_mode: 'bus', transport_submode: 'nightBus'}
    let(:cc_set1) { cc_block.compliance_control_set }
    let(:cc_set2) { create :compliance_control_set }     

  it "sould be unique in a compliance control set" do
    expect( ComplianceControlBlock.new(transport_mode: 'bus', transport_submode: 'nightBus', compliance_control_set: cc_set1) ).not_to be_valid
    expect( ComplianceControlBlock.new(transport_mode: 'bus', transport_submode: 'nightBus', compliance_control_set: cc_set2) ).to be_valid
  end

end
end
