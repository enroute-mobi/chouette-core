RSpec.describe ComplianceControlsController, type: :controller do
  login_user


  let(:compliance_control)        { create(:generic_attribute_control_pattern) }
  let!(:compliance_control_set)   { compliance_control.compliance_control_set }

  describe 'GET #new' do
    it 'should be successful' do
      get :new, compliance_control_set_id: compliance_control_set.id, sti_class: 'GenericAttributeControl::Pattern'
      expect(response).to be_success
    end
  end

  describe 'POST #create' do
    it 'should be successful' do
      post :create, compliance_control_set_id: compliance_control_set.id, compliance_control: compliance_control.as_json.merge(type: 'GenericAttributeControl::Pattern')
      # expect(response).to have_http_status(302)
      # expect(response).to redirect_to compliance_control_set_path(compliance_control_set)
    end
  end

  describe 'GET #select_type' do
    it 'should be successful' do
      get :select_type, compliance_control_set_id: compliance_control_set.id
      expect(response).to be_success
    end
  end

  context "on a control_set the user does not own" do
    describe "GET show" do
      it 'should be successful' do
        get :show, compliance_control_set_id: compliance_control_set.id, id: compliance_control.id
        expect(response).to be_success
      end
    end

    describe 'GET #edit' do
      it 'should be forbidden' do
        get :edit, compliance_control_set_id: compliance_control_set.id, id: compliance_control.id
        expect(response).to have_http_status 403
      end
    end

    describe 'POST #update' do
      it 'should be forbidden' do
        post :update, compliance_control_set_id: compliance_control_set.id, id: compliance_control.id, compliance_control: compliance_control.as_json.merge(type: 'GenericAttributeControl::Pattern')
        expect(response).to have_http_status 403
      end
    end

    describe 'DELETE #destroy' do
      it 'should be forbidden' do
        expect {
          delete :destroy, compliance_control_set_id: compliance_control_set.id, id: compliance_control.id
        }.to change(GenericAttributeControl::Pattern, :count).by(0)
        expect(response).to have_http_status 403
      end
    end
  end

  context "on a control_set the user owns" do
    before(:each){
      compliance_control_set.update organisation: @user.organisation
    }
    describe "GET show" do
      it 'should be successful' do
        get :show, compliance_control_set_id: compliance_control_set.id, id: compliance_control.id
        expect(response).to be_success
      end
    end

    describe 'GET #edit' do
      it 'should be successful' do
        get :edit, compliance_control_set_id: compliance_control_set.id, id: compliance_control.id
        expect(response).to be_success
      end
    end

    describe 'POST #update' do
      it 'should be successful' do
        post :update, compliance_control_set_id: compliance_control_set.id, id: compliance_control.id, compliance_control: compliance_control.as_json.merge(type: 'GenericAttributeControl::Pattern')
        expect(response).to redirect_to compliance_control_set_path(compliance_control_set)
      end
    end

    describe 'DELETE #destroy' do
      it 'should be successful' do
        expect {
          delete :destroy, compliance_control_set_id: compliance_control_set.id, id: compliance_control.id
        }.to change(GenericAttributeControl::Pattern, :count).by(-1)
        expect(response).to have_http_status(302)
      end
    end
  end
end
