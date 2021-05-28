RSpec.describe Api::V1::Internals::NetexExportsController, type: :controller do
  let( :user ){ create :user }
  let(:export_1) { create :netex_export, creator: user.name }
  let(:export_2) { create :netex_export, status: "successful", creator: user.name }

  describe "GET #notify_parent" do
    context 'unauthenticated' do
      include_context 'iboo wrong authorisation internal api'

      it 'should not be successful' do
        get :notify_parent, params: { id: export_1.id, format: :json }
        expect(response).to have_http_status 401
      end
    end

    context 'authenticated' do
      include_context 'iboo authenticated internal api'

      describe "with existing record" do

        before(:each) do
          get :notify_parent, params: { id: export_2.id, format: :json }
        end

        it 'should be successful' do
          expect(response).to have_http_status 200
        end
      end

      describe "with non existing record" do
        it "should throw an error" do
          get :notify_parent, params: { id: 47, format: :json }
          expect(response).to have_http_status 404
        end
      end
    end
  end

  describe "POST #upload" do
    let(:file){ fixture_file_upload('multiple_references_import.zip') }
    context 'unauthenticated' do
      include_context 'iboo wrong authorisation internal api'

      it 'should not be successful' do
        post :upload, params: { id: export_1.id, format: :json, file: file }
        expect(response).to have_http_status 401
        expect(export_1.reload.failed?).to be_truthy
      end
    end

    context 'authenticated' do
      include_context 'iboo authenticated internal api'

      describe "with existing record" do

        before(:each) do
          post :upload, params: { id: export_2.id, format: :json, file: file }
        end

        it 'should be successful' do
          expect(response).to have_http_status 200
          expect(export_2.reload.file).not_to be_nil
          expect(export_2.reload.successful?).to be_truthy
        end
      end

      describe "with non existing record" do
        it "should throw an error" do
          post :upload, params: { id: 42, format: :json, file: file }
          expect(response).to have_http_status 404
        end
      end
    end
  end
end
