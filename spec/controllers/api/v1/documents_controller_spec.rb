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
			let(:document_provider) { workbench.document_providers.create(name: 'document_provider_name') }
			let(:document_type) { workbench.workgroup.document_types.create(name: 'document_type_name', short_name: 'document_type_short_name') }
			let(:code_space) { workbench.workgroup.code_spaces.create(short_name: 'code_space') }
      let(:file) { fixture_file_upload('sample_pdf.pdf') }

			context 'with valid params' do
				it 'should be successful' do
          expect {
            post :create, params: {
              workbench_id: workbench.id,
							document: {
								name: 'test',
								file: file,
								description: '',
								validity_period: {
									from: '2022-06-17'
								},
								document_provider: document_provider.name,
								document_type: document_type.name,
								codes: [
									{ code_space: code_space.short_name, value: 'test' }
								]
							},
              format: :json
            }
          }.to change{Document.count}.by(1)
          expect(response).to be_successful

					document = workbench.documents.last

					expect(document.codes.length).to eq(1)
        end
			end

			context 'with invalid params' do
				it 'should not be successful' do
          expect {
            post :create, params: {
              workbench_id: workbench.id,
							document: { name: 'test' },
              format: :json
            }
          }.to change{Document.count}.by(0)
          expect(response).not_to be_successful
			end
    end
	end


  end
end
