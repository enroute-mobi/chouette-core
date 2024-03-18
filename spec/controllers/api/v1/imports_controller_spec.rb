# frozen_string_literal: true

RSpec.describe Api::V1::ImportsController, type: :controller do
  context 'unauthenticated' do
    include_context 'iboo wrong authorisation api user'

    describe 'GET #index' do
      it 'should not be successful' do
        get :index, params: { workbench_id: workbench.id }
        expect(response).not_to be_successful
      end
    end
  end

  context 'authenticated' do
    include_context 'iboo authenticated api user'

    describe 'GET #index' do
      it 'should be successful' do
        get :index, params: { workbench_id: workbench.id, format: :json }
        expect(response).to be_successful
      end
    end

    describe 'POST #create' do
      let(:file) { fixture_file_upload('multiple_references_import.zip') }

      context 'in a worbench with no restriction' do
        before do
          workbench.restrictions = []
          workbench.save
        end

        it 'should be successful' do
          expect {
            post :create, params: {
              workbench_id: workbench.id,
              workbench_import: {
                name: 'test',
                file: file,
                creator: 'test',
                notification_target: 'workbench',
                options: {
                  'automatic_merge': true,
                  'flag_urgent': true,
                  'merge_method': 'experimental'
                }
              },
              format: :json
            }
          }.to change{Import::Workbench.count}.by(1)
          expect(response).to be_successful

          import = Import::Workbench.last
          expect(import.automatic_merge).to be_truthy
          expect(import.flag_urgent).to be_truthy
          expect(import.notification_target).to eq('workbench')
          expect(import.merge_method).to eq('experimental')
        end
      end

      context 'in a worbench with flag_urgent restriction' do
        before do
          workbench.restrictions = ["referentials.flag_urgent"]
          workbench.save
        end

        it "should remove urgent option and allow import" do
          expect {
            post :create, params: {
              workbench_id: workbench.id,
              workbench_import: {
                name: 'test',
                file: file,
                creator: 'test',
                options: {
                  'automatic_merge': true,
                  'flag_urgent': true,
                  'merge_method': 'legacy'
                }
              },
              format: :json
            }
          }.to change{Import::Workbench.count}.by(1)
          expect(response).to be_successful

          import = Import::Workbench.last
          expect(import.flag_urgent).to be_falsy
        end

      end
    end
  end
end
