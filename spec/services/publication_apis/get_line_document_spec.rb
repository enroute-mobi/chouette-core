RSpec.describe PublicationApis::GetLineDocument do
  let(:context) do
    Chouette.create do
			workgroup do
				document_type :pdf, name: 'pdf', short_name: 'pdf'

				document_provider do
					document :first_doc, document_type: :pdf, validity_period: Period.from(Date.today)
					document :second_doc, document_type: :pdf, validity_period: Period.from(Date.today)
					document :third_doc, document_type: :pdf, validity_period: Period.from(Date.tomorrow)
				end

				line :line, registration_number: '1', documents: [:first_doc, :second_doc, :third_doc]

				referential lines: [:line]

			end
    end
  end

  let(:referential) { context.referential }
	let(:service) { PublicationApis::GetLineDocument.new(referential: referential, registration_number: '1', document_type: 'test') }

	describe 'when line is not found' do
		it 'should raise PublicationApi::LineNotFoundError' do
			allow(service).to receive(:registration_number) { 'toto' }
			expect { service.call }.to raise_error(PublicationApi::LineNotFoundError)
		end
	end

	describe 'when line is found' do
		describe 'when document is not found' do
			it 'should raise PublicationApi::DocumentNotFoundError' do
				allow(service).to receive(:registration_number) { '1' }
				allow(service).to receive(:document_type) { '1' }

				expect { service.call }.to raise_error(PublicationApi::DocumentNotFoundError)
			end
		end

		describe 'when document is found' do
			let(:document1) { context.document(:first_doc) }
			let(:document2) { context.document(:second_doc) }
			let(:document3) { context.document(:third_doc) }

			it 'should return last updated document (with validity period containing current date)' do
				allow(service).to receive(:registration_number) { '1' }
				allow(service).to receive(:document_type) { 'pdf' }

				expect(service.call).to eq(document2)

				document1.touch
				document1.reload

				expect(service.call).to eq(document1)
			end
		end
	end
end
