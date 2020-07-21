
RSpec.describe PublicationApisController, type: :controller do
  login_user
  render_views

  let(:workbench){ create :workbench, organisation: organisation }
  let(:workgroup){ workbench.workgroup }
  let(:publication_api_params){ { name: "Demo", slug: "demo" } }
  let(:publication_api){ create(:publication_api, workgroup: workgroup) }

  before(:each){
    workgroup.update owner: organisation
  }

  describe "GET index" do
    let(:request){ get :index, params: { workgroup_id: workgroup.id }}
    it "should be ok" do
      request
      expect(response).to be_successful
    end
  end

  describe "GET new" do
    let(:request){ get :new, params: { workgroup_id: workgroup.id }}
    it "should not be ok" do
      request
      expect(response).not_to be_successful
    end

    with_permission "publication_apis.create" do
      it "should be ok" do
        request
        expect(response).to be_successful
      end
    end

    describe "POST create" do
      let(:request){ post :create, params: { workgroup_id: workgroup.id, publication_api: publication_api_params }}
      it "should not be ok" do
        request
        expect(response).not_to be_successful
      end

      with_permission "publication_apis.create" do
        it "should be ok" do
          request
          expect(response).to be_redirect
        end
      end
    end

    describe "GET edit" do
      let(:request){ get :edit, params: { workgroup_id: workgroup.id, id: publication_api.id }}
      it "should not be ok" do
        request
        expect(response).not_to be_successful
      end

      with_permission "publication_apis.update" do
        it "should be ok" do
          request
          expect(response).to be_successful
        end
      end
    end

    describe "POST update" do
      let(:request){ post :update, params: { workgroup_id: workgroup.id, id: publication_api.id, publication_api: publication_api_params }}
      it "should not be ok" do
        request
        expect(response).not_to be_successful
      end

      with_permission "publication_apis.update" do
        it "should be ok" do
          request
          expect(response).to be_redirect
        end
      end
    end
  end
end
