RSpec.describe NotificationRule::Workbench, type: :model do
	describe '#recipients' do
		before do
			3.times do
				subject.workbench.organisation.users << create(:user)
			end
		end

		let(:workbench) { subject.workbench }
	
		it 'should return a collection with only on user' do
			expect(subject.recipients).to match_array(workbench.users)
		end
	end
end
