RSpec.describe GetLineDocument do
  let(:context) do
    Chouette.create do
      line :line, registration_number: '1'

      referential lines: [:line]
    end
  end

	let(:workgroup) { context.workgroup }
	let(:workbench) { workgroup.workbenches.first }
  let(:referential) { context.referential }
  let(:line) { referential.lines.first }

	let(:document_provider) { workbench.document_providers.create(name: 'document_provider') }
	let(:document_type) { workgroup.document_types.create(name: 'test', short_name: 'test') }
	let(:file) { fixture_file_upload('sample_pdf.pdf') }

	let(:service) { GetLineDocument.new(referential: referential, registration_number: '1', document_type: 'test') }

	describe 'when line is not found' do
		it 'should raise GetLineDocument::LineNotFoundError' do
			allow(service).to receive(:registration_number) { 'toto' }
			expect { service.call }.to raise_error(GetLineDocument::LineNotFoundError)
		end
	end

	describe 'when line is found' do
		describe 'when document is not found' do
			it 'should raise GetLineDocument::DocumentNotFoundError' do
				allow(service).to receive(:registration_number) { '1' }
				allow(service).to receive(:document_type) { '1' }

				expect { service.call }.to raise_error(GetLineDocument::DocumentNotFoundError)
			end
		end

		describe 'when document is found' do
			let(:document1) { Document.create(document_type: document_type, document_provider: document_provider, name: '1', file: file, validity_period: Range.new(Date.today, nil)) }
			let(:document2) { Document.create(document_type: document_type, document_provider: document_provider, name: '2', file: file, validity_period: Range.new(Date.today + 1.day, nil)) }
			let(:document3) { Document.create(document_type: document_type, document_provider: document_provider, name: '3', file: file, validity_period: Range.new(Date.today, nil)) }

			before do
				DocumentMembership.create(document: document1, documentable: line)
				DocumentMembership.create(document: document2, documentable: line)
				DocumentMembership.create(document: document3, documentable: line)
			end

			it 'should return last updated document (with validity period containing current date)' do
				allow(service).to receive(:registration_number) { '1' }
				allow(service).to receive(:document_type) { 'test' }

				expect(service.call).to eq(document3)

				document1.touch
				document1.reload

				expect(service.call).to eq(document1)
			end
		end
	end
end
