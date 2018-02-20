RSpec.describe StatusesController, :type => :controller do

  describe "GET index" do
    login_user
    render_views


    let(:request){ get :index}
    let(:parsed_response){ JSON.parse response.body }
    it "should be ok" do
      request
      expect(response).to have_http_status 200
      expect(parsed_response["status"]).to eq "ok"
    end
    context "without blocked object" do
      before do
        create :referential
        create :import
        create :compliance_check_set
        request
      end

      it "should be ok" do
        expect(response).to have_http_status 200
        expect(parsed_response["status"]).to eq "ok"
        expect(parsed_response["referentials_blocked"]).to eq 0
        expect(parsed_response["imports_blocked"]).to eq 0
        expect(parsed_response["imports_blocked"]).to eq 0
      end
    end

    context "with a blocked object" do
      before do
        create :referential, created_at: 5.hours.ago, ready: false
        create :import
        create :compliance_check_set
        request
      end

      it "should be ko" do
        expect(Referential.blocked.count).to eq 1
        expect(response).to have_http_status 200
        expect(parsed_response["status"]).to eq "ko"
        expect(parsed_response["referentials_blocked"]).to eq 1
        expect(parsed_response["imports_blocked"]).to eq 0
        expect(parsed_response["imports_blocked"]).to eq 0
      end
    end
  end
end
