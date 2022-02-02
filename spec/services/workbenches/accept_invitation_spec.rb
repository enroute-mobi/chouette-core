RSpec.describe Workbenches::AcceptInvitation, type: :service do
	let(:organisation) { FactoryBot.create(:organisation, code: 'bar') }

	before do
		FactoryBot.create(:workbench, organisation_id: nil, prefix: nil, status: :pending, invitation_code: 'test')
	end

	describe '#call' do
		context 'when confirmation_code is valid' do
			let(:service) { described_class.new(confirmation_code: 'test', organisation_id: organisation.id) }
		
			it 'should accept the invitation code' do
				byebug
				result = service.call

				expect(result).to be_a_kind_of(Workbench)
				expect(result.accepted?).to be_truthy
				expect(result.prefix).to eq(organisation.code)
				expect(result.organisation_id).to eq(organisation.id)
			end
		end

		context 'when confirmation_code is not valid' do
			let(:service) { described_class.new(confirmation_code: 'foo', organisation_id: organisation.id) }

			it 'should not accept the invitation code' do
				result = service.call

				expect(result).to be_falsey
			end
		end

		context 'when organisation_id is not valid' do
			let(:service) { described_class.new(confirmation_code: 'test', organisation_id: 'foo') }

			it 'should not accept the invitation code' do
				result = service.call

				expect(result).to be_falsey
			end
		end
	end
end
