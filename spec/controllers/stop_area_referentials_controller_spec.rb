RSpec.describe StopAreaReferentialsController, :type => :controller do
  login_user

  let(:stop_area_referential) { create :stop_area_referential }

  describe 'PUT sync' do
    let(:request){ put :sync, id: stop_area_referential.id }

    it 'should respond with 403' do
      expect(request).to have_http_status 403
    end

    with_permission "stop_area_referentials.synchronize" do
      it 'returns HTTP success' do
        expect(request).to redirect_to [stop_area_referential]
      end
    end
  end
end
