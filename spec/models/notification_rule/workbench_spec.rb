RSpec.describe NotificationRule::Workbench, type: :model do
	let(:context) do
		Chouette.create do
			organisation :owner do
				user :first
				user :last
			end

			workbench :first, organisation: :owner do
				notification_rule :first, target_type: 'workbench'
			end
		end
	end

	let(:workbench) { context.workbench(:first) }
	let(:notification_rule) { context.notification_rule(:first) }

	describe '#recipients' do
		it 'should return a collection with only on user' do
			expect(notification_rule.recipients).to match_array(workbench.users)
			expect(notification_rule.recipients.length).to eq(2)
		end
	end
end
