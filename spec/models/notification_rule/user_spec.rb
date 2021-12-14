RSpec.describe NotificationRule::User, type: :model do
	let(:context) do
		Chouette.create do
			organisation :owner do
				user :first
				user :last
			end
			workbench :first, organisation: :owner do
				notification_rule :first, target_type: 'user', user_ids: [nil]
			end
		end
	end

	let(:notification_rule) { context.notification_rule(:first) }
	let(:workbench) { context.workbench(:first) }

	it 'should validate taht length of users_ids is at least 1' do
		notification_rule.user_ids = []
		expect(notification_rule.valid?).to be_falsey

		notification_rule.user_ids = [1,2]
		expect(notification_rule.valid?).to be_truthy
	end

	describe '#recipients' do
		it 'should return a collection with only on user' do
			users = workbench.users.limit(1)
			allow(notification_rule).to receive(:users_ids) { users.pluck(:id) }

			expect(notification_rule.recipients).to match_array(users)
		end
	end
end
