RSpec.describe Chouette::Netex::RoutePoint, type: :netex_resource do
  let(:resource){ create :stop_point }
  before do
    resource.stop_area.update area_type: :zdlp
  end

  it 'should have the correct attributes' do
    expect(node[:id]).to eq resource.objectid.gsub('StopPoint', 'RoutePoint')
  end

  it_behaves_like 'it has one child with ref', 'projections PointProjection ProjectToPointRef', ->{ resource.objectid.gsub('StopPoint', 'ScheduledStopPoint') }
end
