# frozen_string_literal: true

RSpec.describe Api::V1::DocumentsController, type: :controller do
  context 'unauthenticated' do
    include_context 'iboo wrong authorisation api user'

    describe 'POST #create' do
      it 'should not be successful' do
        post :create, params: { workbench_id: workbench.id, document: {} }
        expect(response).not_to be_successful
      end
    end
  end

  context 'authenticated' do
    include_context 'iboo authenticated api user'

    describe 'POST #create' do
      let(:document_type) do
        workbench.workgroup.document_types.create(name: 'document_type_name', short_name: 'document_type_short_name')
      end
      let(:code_space) { workbench.workgroup.code_spaces.create(short_name: 'code_space') }
      let(:file) { fixture_file_upload('sample_pdf.pdf') }

      context 'with valid params' do
        it 'should be successful' do
          expect do
            post :create, params: {
              workbench_id: workbench.id,
              document: {
                name: 'test',
                file: file,
                description: '',
                validity_period: {
                  from: '2022-06-17'
                },
                document_type: document_type.short_name,
                codes: { '0' => { code_space: code_space.short_name, value: 'test' } }
              },
              format: :json
            }
          end.to change { Document.count }.by(1)
          expect(response).to be_successful

          document = workbench.documents.last
          expect(document.file).to be_present
          expect(document.codes.length).to eq(1)
        end
      end

      context 'with invalid params' do
        it 'should not be successful' do
          expect do
            post :create, params: {
              workbench_id: workbench.id,
              document: { name: 'test' },
              format: :json
            }
          end.to change { Document.count }.by(0)
          expect(response).not_to be_successful
        end
      end
    end
  end
end
