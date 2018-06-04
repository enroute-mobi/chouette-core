require 'rails_helper'

RSpec.describe Api::V1::Internals::ComplianceCheckSetsController, type: :controller do
  let(:check_set_1) { create :compliance_check_set }
  let(:check_set_2) { create :compliance_check_set, parent: create(:import) }

  describe "GET #notify_parent" do
    context 'unauthenticated' do
      include_context 'iboo wrong authorisation internal api'

      it 'should not be successful' do
        get :notify_parent, id: check_set_1.id, format: :json
        expect(response).to have_http_status 401
      end
    end

    context 'perform_internal_checks' do
      it "should be called" do
        expect_any_instance_of(ComplianceCheckSet).to receive(:perform_internal_checks)
        request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials( Rails.application.secrets.api_token)
        get :notify_parent, id: check_set_2.id, format: :json
      end
    end

    context 'authenticated' do
      include_context 'iboo authenticated internal api'

      describe "with existing record" do

        before(:each) do
          get :notify_parent, id: check_set_2.id, format: :json
        end

        it 'should be successful' do
          expect(response).to have_http_status 200
        end

        describe "that has a parent" do
          it "calls #notify_parent on the import" do
            expect(check_set_2.reload.notified_parent_at).not_to be_nil
          end
        end

        describe "that does not have a parent" do
          xit "should not be successful" do
            expect(response.body).to include("error")
          end
        end

      end

      describe "with non existing record" do
        it "should throw an error" do
          get :notify_parent, id: 47, format: :json
          expect(response.body).to include("error")
        end
      end
    end
  end
end
