RSpec.describe Chouette::Netex::ScheduledStopPoint, type: :netex_resource do
  let(:resource){ create :stop_point }

  it 'should have the correct id' do
    expect(node[:id]).to eq resource.objectid.gsub('StopPoint', 'ScheduledStopPoint')
  end
end
