RSpec.describe Api::V1::WorkbenchController, type: :controller do

  describe Api::V1::WorkbenchController::Authentication do

    let(:scope) { double find_by: api_key }
    let(:token) { double "Token" }
    let(:api_key) { double "API Key", workbench: workbench }
    let(:workbench) { double "Workbench associated to API Key", organisation: organisation  }
    let(:organisation) { double "Organisation associated to the Workbench", code: 'test' }

    let(:authentication) do
      Api::V1::WorkbenchController::Authentication.new scope, token: token
    end

    describe "#valid?" do

      subject { authentication.valid? }

      context "when API key isn't found" do
        before { allow(authentication).to receive(:api_key).and_return nil }
        it { is_expected.to be(false) }
      end

      context "when organisation code isn't valid" do
        before { allow(authentication).to receive(:valid_organisation_code?).and_return false }
        it { is_expected.to be(false) }
      end

      context "when API key is present and organisation code is valid" do
        before do
          allow(authentication).to receive(:api_key).and_return double
          allow(authentication).to receive(:valid_organisation_code?).and_return true
        end
        it { is_expected.to be(true) }
      end

    end

    describe "#api_key" do

      context "when scope is a Workbench" do

        let(:context) { Chouette.create { workbench } }
        let(:scope) { context.workbench.api_keys }

        subject { authentication.api_key }

        context "when API Key exists in the Workbench with the given token" do

          let(:api_key) { context.workbench.api_keys.create! }
          let(:token) { api_key.token }

          it "return this API key" do
            expect(subject).to eq(api_key)
            expect(subject.token).to eq(authentication.token)
          end

        end

        context "when no API key exists with the given token" do

          let(:token) { 'dummy' }

          it { is_expected.to be_nil }

        end

      end

    end

    describe "#validate" do

      subject { authentication.validate {} }

      context "when authentification is valid" do

        it { is_expected.to be(true) }

        it "yield the given block" do
          expect { |b| authentication.validate(&b) }.to yield_control
        end

      end

      context "when authentification isn't valid" do

        before { allow(authentication).to receive(:valid?).and_return(false) }

        it { is_expected.to be(false) }

        it "don't yield the given block" do
          expect { |b| authentication.validate(&b) }.to_not yield_control
        end

      end

    end

    describe "#workbench" do

      subject { authentication.workbench }

      context "when API key is found" do
        it { is_expected.to be(api_key.workbench) }
      end

      context "when no API key is found" do
        before { allow(authentication).to receive(:api_key).and_return nil }
        it { is_expected.to be_nil }
      end

    end

    describe "#organisation" do

      subject { authentication.organisation }

      context "when API key is found" do
        it { is_expected.to be(api_key.workbench.organisation) }
      end

      context "when no API key is found" do
        before { allow(authentication).to receive(:api_key).and_return nil }
        it { is_expected.to be_nil }
      end

    end

  end

  describe "#authentication_scheme" do

    subject { controller.send :authentication_scheme }

    it "returns the request authentification scheme (in downcase as symbol)" do
      allow(controller.request).to receive(:authorization).and_return("Dummy")
      is_expected.to be(:dummy)
    end

    it "returns nil when no authentification is found" do
      is_expected.to be_nil
    end

  end

  describe "#authentication_scope" do

    subject { controller.send :authentication_scope }

    context "when the request uses an existing Workbench identifier" do
      before { allow(controller).to receive(:params).and_return(workbench_id: workbench.id) }

      let(:context) { Chouette.create { workbench } }
      let(:workbench) { context.workbench }

      it "is api keys collection of this Workbench" do
        is_expected.to eq(workbench.api_keys)
      end

    end

    context "when the request uses an unknown Workbench identifier" do
      before { allow(controller).to receive(:params).and_return(workbench_id: "dummy") }

      it "raises an ActiveRecord::NotFound error" do
        expect { subject }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

  end

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
