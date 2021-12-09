RSpec.describe NotificationCenter::NotifyUsers do
	context '#recipients' do
		let(:operation) { FactoryBot.build(:import, notification_target: 'user') }
	
		context '#without notification rules' do
			it 'should return operation#notification_users' do
				Array.new(4) do |i|
					build_list(:user, i + 1)
				end.map do |users|
					allow(operation).to receive(:notification_users) { users }

					service = NotificationCenter::NotifyUsers.new(operation, [])

					expect(service.recipients).to match_array(users.map(&:email_recipient))
				end
			end
		end

		context 'with a block notification rule' do
			it 'should remove recipients from the list' do
				users = build_list(:user, 2)
				notification_rule = NotificationRule.new(rule_type: 'block')
				service = NotificationCenter::NotifyUsers.new(operation, [])

				allow(notification_rule).to receive(:recipients) { [*users, FactoryBot.build(:user)] }
				allow(service).to receive(:notification_rules) { [notification_rule] }
				allow(operation).to receive(:notification_users) { users }

				expect(service.recipients).to be_empty
			end
		end

		context 'with a notify notification rule' do
			it 'should add recipients from the list' do
				users = build_list(:user, 2)
				notification_rule = NotificationRule.new(rule_type: 'notify')
				service = NotificationCenter::NotifyUsers.new(operation, [])

				expected_users = [*users, FactoryBot.build(:user)]

				allow(notification_rule).to receive(:recipients) { expected_users }
				allow(service).to receive(:notification_rules) { [notification_rule] }
				allow(operation).to receive(:notification_users) { users }

				expect(service.recipients).to match_array(expected_users.map(&:email_recipient))
			end
		end
	end

	context '#notification_rules' do
		let(:operation) { FactoryBot.build(:import) }
	
		it 'should return the right scope' do
			service = NotificationCenter::NotifyUsers.new(operation, [])

			expected_scope = service.workbench
				.notification_rules
				.active
				.for_operation(operation, [])
				.order(priority: :asc)

			expect(service.notification_rules.to_sql).to eq(expected_scope.to_sql)
		end
	end
end
