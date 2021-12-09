RSpec.describe NotificationRule::User, type: :model do
	it { should validate_length_of(:user_ids).is_at_least(1) }

	describe '#recipients' do
		before do
			3.times do
				subject.workbench.organisation.users << create(:user)
			end
		end

		let(:workbench) { subject.workbench }
	
		it 'should return a collection with only on user' do
			users = workbench.users.limit(1)
			allow(subject).to receive(:users_ids) {users.pluck(:id) }

			expect(subject.recipients).to match_array(users)
		end
	end
end
