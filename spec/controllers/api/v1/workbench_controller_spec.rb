RSpec.describe Api::V1::WorkbenchController, type: :controller do
  context '#authenticate' do
    before do
      # It appears that controller.send(:authenticate) throw an errror while testing because the request headers can't be properly instanciated this way
      # Since Api::V1::WorkbenchController has no entry point, the request has to be sent to Api::V1::ImportsController for #authentification testing purposes
      @controller = Api::V1::ImportsController.new
    end
    context "with basic authentification" do
      context "with right credentials" do
        include_context 'iboo authenticated api user'
        before do
          get :index, params: { workbench_id: workbench.id, format: :json }
        end

        it "should return a 200 status" do
          expect(response.status).to eq(200)
        end

        it "should set the current workbench" do
          expect(assigns(:current_workbench)).to eq api_key.workbench
        end

      end

      context "with wrong credentials" do
        include_context 'iboo wrong authorisation api user'
        before do
          get :index, params: { workbench_id: workbench.id, format: :json }
        end

        it "should return a 401 status" do
          expect(response.status).to eq(401)
        end

        it "shouldn't set the current workbench" do
          expect(assigns(:current_workbench)).to be_nil
        end

      end
    end


    context "with token authentification" do
      let(:workbench) { create(:workbench) }

      context "with right credentials" do
        include_context 'right api token authorisation'
        before do
          get :index, params: { workbench_id: workbench.id, format: :json }
        end

        it "should return a 200 status" do
          expect(response.status).to eq(200)
        end

        it "should set the current workbench" do
          expect(assigns(:current_workbench)).to eq api_key.workbench
        end

      end

      context "with wrong credentials" do
        include_context 'wrong api token authorisation'
        before do
          get :index, params: { workbench_id: workbench.id, format: :json }
        end

        it "should return a 401 status" do
          expect(response.status).to eq(401)
        end

        it "shouldn't set the current workbench" do
          expect(assigns(:current_workbench)).to be_nil
        end

      end
    end

    context "with another workbench id param" do
      let(:workbench) { create(:workbench) }
      include_context 'right api token authorisation'
      before do
        get :index, params: { workbench_id: (workbench.id+1), format: :json }
      end

      it "should return a 401 status" do
        expect(response.status).to eq(401)
      end

      it "shouldn't set the current workbench" do
        expect(assigns(:current_workbench)).to be_nil
      end
      
    end

  end
end
