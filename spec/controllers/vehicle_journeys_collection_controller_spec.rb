RSpec.describe VehicleJourneysCollectionsController, :type => :controller do
  let(:referential){ create :referential }
  let(:route){ create :route, referential: referential }
  let(:line){ route.line }
  let( :user_context ){ UserContext.new(@user, referential: referential) }

  before do
    @user = build_stubbed(:allmighty_user, organisation: referential.organisation)
    allow(controller).to receive(:current_organisation).and_return(@user.organisation)
    allow(controller).to receive(:pundit_user).and_return(user_context)
  end

  describe "PUT update" do
    login_user

    it "should allow updates" do
      expect(response).to have_http_status 200
    end

    context "when the referential is in pending state" do
      before(:each){ referential.pending! }
      let!(:request){ put :update, referential_id: referential.id, line_id: line.id, route_id: route.id, format: :json}

      it "should deny updates" do
        expect(response).to have_http_status 403
      end
    end

    context "when the referential is in archived state" do
      before(:each){ referential.archived! }
      let!(:request){ put :update, referential_id: referential.id, line_id: line.id, route_id: route.id, format: :json}

      it "should deny updates" do
        expect(response).to have_http_status 403
      end
    end
  end
end
