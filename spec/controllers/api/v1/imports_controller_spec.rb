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
          expect do
            post :create, params: {
              workbench_id: workbench.id,
              workbench_import: {
                name: 'test',
                file: file,
                creator: 'test',
                options: {
                  automatic_merge: true,
                  archive_on_fail: true,
                  flag_urgent: true
                }
              },
              format: :json
            }
          end.to change { Import::Workbench.count }.by(1)
          expect(response).to be_successful

          import = Import::Workbench.last
          expect(import.file).to be_present
          expect(import.automatic_merge).to be_truthy
          expect(import.archive_on_fail).to be_truthy
          expect(import.flag_urgent).to be_truthy
        end

        it 'should ignore unsupported options' do
          expect do
            post :create, params: {
              workbench_id: workbench.id,
              workbench_import: {
                name: 'test',
                file: file,
                creator: 'test',
                options: {
                  notification_target: 'workbench'
                }
              },
              format: :json
            }
          end.to change { Import::Workbench.count }.by(1)
          expect(response).to be_successful

          import = Import::Workbench.last
          expect(import.file).to be_present
          expect(import.notification_target).not_to eq('workbench')
        end
      end

      context 'in a worbench with flag_urgent restriction' do
        before do
          workbench.restrictions = ['referentials.flag_urgent']
          workbench.save
        end

        it 'should remove urgent option and allow import' do
          expect do
            post :create, params: {
              workbench_id: workbench.id,
              workbench_import: {
                name: 'test',
                file: file,
                creator: 'test',
                options: {
                  automatic_merge: true,
                  archive_on_fail: true,
                  flag_urgent: true
                }
              },
              format: :json
            }
          end.to change { Import::Workbench.count }.by(1)
          expect(response).to be_successful

          import = Import::Workbench.last
          expect(import.flag_urgent).to be_falsy
        end
      end
    end
  end
end
