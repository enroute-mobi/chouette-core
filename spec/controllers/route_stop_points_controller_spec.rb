
RSpec.describe RouteStopPointsController, type: :controller do
  login_user

  let(:referential) { Referential.first }
  let!(:line) { create :line, referential: referential }
  let!(:route) { create :route, line: line }

  describe 'GET index' do
    before(:each) { get :index, params: { referential_id: referential.id, line_id: line.id, route_id: route.id, format: :json }}

    it 'returns HTTP success' do
      expect(response).to be_successful
    end

    it 'returns a JSON of stop areas' do
      expect(response.body).to eq(route.stop_points.map { |sp| { id: sp.id, stop_area_id: sp.stop_area.id, name: sp.name, zip_code: sp.stop_area.zip_code, city_name: sp.stop_area.city_name } }.to_json)
    end
  end
end
