require 'rails_helper'

RSpec.describe ComplianceControlBlocksController, type: :controller do
  login_user

  let(:compliance_control_block)        { create(:compliance_control_block) }
  let!(:compliance_control_set)         { compliance_control_block.compliance_control_set }
  let(:compliance_control_block_params) { compliance_control_block.as_json.merge(block_kind: :transport_mode, transport_mode: "metro", transport_submode: 'undefined') }

  before(:each){
    compliance_control_set.update organisation: @user.organisation
  }
  describe 'GET #new' do
    it 'should be successful' do
      get :new, params: { compliance_control_set_id: compliance_control_set.id, id: compliance_control_block.id }
      expect(response).to be_successful
    end
  end

  describe 'POST #create' do
    it 'should be successful' do
      post :create, params: { compliance_control_set_id: compliance_control_set.id, compliance_control_block: compliance_control_block_params }
      expect(response).to redirect_to compliance_control_set_path(compliance_control_set)
    end
  end

  describe 'GET #edit' do
    it 'should be successful' do
      get :edit, params: { compliance_control_set_id: compliance_control_set.id, id: compliance_control_block.id }
      expect(response).to be_successful
    end
  end

  describe 'POST #update' do
    it 'should be successful' do
      post :update, params: {
        compliance_control_set_id: compliance_control_set.id,
        id: compliance_control_block.id,
        compliance_control_block: compliance_control_block_params
      }
      expect(response).to redirect_to compliance_control_set_path(compliance_control_set)
    end
  end

  describe 'DELETE #destroy' do
    it 'should be successful' do
      expect {
        delete :destroy, params: { compliance_control_set_id: compliance_control_set.id, id: compliance_control_block.id }
      }.to change(ComplianceControlBlock, :count).by(-1)
      expect(response).to redirect_to compliance_control_set_path(compliance_control_set)
    end
  end
end
