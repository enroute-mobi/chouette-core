RSpec.describe StopAreasController, :type => :controller do
  login_user

  let(:stop_area_referential) { create :stop_area_referential, member: @user.organisation }
  let(:stop_area) { create :stop_area, stop_area_referential: stop_area_referential }

  describe 'PUT deactivate' do
    let(:request){ put :deactivate, id: stop_area.id, stop_area_referential_id: stop_area_referential.id }

    it 'should respond with 403' do
      expect(request).to have_http_status 403
    end

    with_permission "stop_areas.change_status" do
      it 'returns HTTP success' do
        expect(request).to redirect_to [stop_area_referential, stop_area]
        expect(stop_area.reload).to be_deactivated
      end
    end
  end

  describe 'PUT activate' do
    let(:request){ put :activate, id: stop_area.id, stop_area_referential_id: stop_area_referential.id }
    before(:each){
      stop_area.deactivate!
    }
    it 'should respond with 403' do
      expect(request).to have_http_status 403
    end

    with_permission "stop_areas.change_status" do
      it 'returns HTTP success' do
        expect(request).to redirect_to [stop_area_referential, stop_area]
        expect(stop_area.reload).to be_activated
      end
    end
  end
end
