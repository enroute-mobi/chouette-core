# frozen_string_literal: true

RSpec.describe Api::V1::Internals::NetexImportsController, type: :controller do
  let(:import_1) { create :netex_import }
  let(:import_2) { create :netex_import, status: "successful" }
  let(:workbench) { create :workbench, organisation: organisation }

  describe 'POST #create' do
    let(:file) { fixture_file_upload('multiple_references_import.zip') }
    let(:attributes){{
      name: "Nom",
      file: file,
      workbench_id: workbench.id,
      parent_id: import_1.id,
      parent_type: import_1.class.name,
    }}

    context 'unauthenticated' do
      include_context 'iboo wrong authorisation internal api'

      it 'should not be successful' do
        post :create, params: { format: :json, netex_import: attributes }
        expect(response).to have_http_status 401
      end
    end

    context 'authenticated' do
      include_context 'iboo authenticated internal api'

      it 'should be successful' do
        import_1
        expect {
          post :create, params: { format: :json, netex_import: attributes }
        }.to change{Import::Netex.count}.by(1)
        expect(response).to be_successful
        import = Import::Base.last
        expect(import).to have_attributes({
                                            'name' => 'Nom',
                                            'parent_id' => import_1.id
                                          })
        expect(import.file).to be_present
      end
    end
  end

  describe "GET #notify_parent" do
    context 'unauthenticated' do
      include_context 'iboo wrong authorisation internal api'

      it 'should not be successful' do
        get :notify_parent, params: { id: import_1.id, format: :json }
        expect(response).to have_http_status 401
      end
    end

    context 'authenticated' do
      include_context 'iboo authenticated internal api'

      describe "with existing record" do

        before(:each) do
          get :notify_parent, params: { id: import_2.id, format: :json }
        end

        it 'should be successful' do
          expect(response).to have_http_status 200
        end

        it "calls #notify_parent on the import" do
          expect(import_2.reload.notified_parent_at).not_to be_nil
        end
      end

      describe "with non existing record" do
        it "should throw an error" do
          get :notify_parent, params: { id: 47, format: :json }
          expect(response.body).to include("error")
        end
      end
    end
  end

  describe 'GET #download' do
    context 'authenticated' do
      include_context 'iboo authenticated internal api'

      it 'should be successful' do
        get :download, params: { id: import_2.id }
        expect(response).to be_successful
        expect(response.body).to eq(import_2.file.read)
      end
    end
  end
end
