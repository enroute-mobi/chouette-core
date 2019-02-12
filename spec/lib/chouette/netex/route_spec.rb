RSpec.describe Chouette::Netex::Route, type: :netex_resource do
  let(:resource){ create :route, :with_opposite, name: "Nom de la route", published_name: "Nom de la route publié" }

  it_behaves_like 'it has default netex resource attributes'

  it_behaves_like 'it has children matching attributes', {
    'Name'            => :published_name,
    'DirectionType'   => :wayback,
  }

  it_behaves_like 'it has one child with ref', 'LineRef', ->{ resource.line.objectid }
  it_behaves_like 'it has one child with ref', 'InverseRouteRef', ->{ resource.opposite_route.objectid }

  it 'should have a PointOnRoute for each stop_point' do
    expect(resource.stop_points).to be_present
    resource.stop_points.each_with_index do |sp, i|
      id = sp.objectid.gsub('StopPoint', 'PointOnRoute')
      expect(node.css("PointOnRoute[id='#{id}']").count).to eq 1
      ref = sp.objectid.gsub('StopPoint', 'RoutePoint')
      expect(node.css("PointOnRoute[id='#{id}'] RoutePointRef[ref='#{ref}']").count).to eq 1
    end
  end
end
