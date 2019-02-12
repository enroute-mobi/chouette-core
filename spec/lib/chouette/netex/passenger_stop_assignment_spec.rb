RSpec.describe Chouette::Netex::PassengerStopAssignment, type: :netex_resource do
  let(:resource){ create :stop_point }
  before do
    resource.stop_area.update area_type: :zdlp
  end

  it 'should have the correct attributes' do
    expect(node[:id]).to eq resource.objectid.gsub('StopPoint', 'PassengerStopAssignment')
    expect(node[:order]).to eq '0'
  end

  it_behaves_like 'it has one child with ref', 'ScheduledStopPointRef', ->{ resource.objectid.gsub('StopPoint', 'ScheduledStopPoint') }
  it_behaves_like 'it has one child with ref', 'StopPlaceRef', ->{ resource.stop_area.objectid }

  context 'with a zdep parent' do
    before do
      resource.stop_area.update area_type: :zdep
    end

    it_behaves_like 'it has no child', 'StopPlaceRef'
    it_behaves_like 'it has one child with ref', 'QuayRef', ->{ resource.stop_area.objectid }
  end
end
