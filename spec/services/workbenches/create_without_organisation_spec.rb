RSpec.describe Workbenches::CreateWithoutOrganisation, type: :service do
	let(:context) do
		Chouette.create do
			organisation :orga

			workgroup owner: :orga
		end
	end

	let(:workgroup) { context.workgroup }
	let(:service) { described_class.new(name: 'test', workgroup: workgroup) }

	describe '#call' do
		it 'should create a workbench with an invitation code' do
			workbench = service.call

			expect(workbench).to be_valid

			expect(workbench.pending?).to be_truthy
			expect(workbench.invitation_code).to be
		end
	end
end
