RSpec.describe Query::NotificationRule do

  let(:context) do
    Chouette.create do
      organisation :owner_organisation do
        user :first, name: 'ABC', email: 'abc@def.com'
				user :last, name: 'Test', email: 'test@test.com'
      end

			workgroup owner: :owner_organisation do
				workbench :email, organisation: :owner_organisation do
					notification_rule :workbench, target_type: 'workbench'
					notification_rule :user, target_type: 'user', users: [:last]
					notification_rule :external_email, target_type: 'external_email', external_email: 'external@email.com'
				end
			end

			workbench :period do
				notification_rule :in_period, period: Period.from(:yesterday).until(:tomorrow)
				notification_rule :out_of_period, period: Period.before(:today).during(10.days)
			end

			workbench :rule_type do
				notification_rule :block, rule_type: 'block'
				notification_rule :notify, rule_type: 'notify'
			end

			workbench :operation_statuses do
				notification_rule :all_statuses, operation_statuses: []
				notification_rule :successful, operation_statuses: ['successful']
				notification_rule :warning, operation_statuses: ['warning']
				notification_rule :failed, operation_statuses: ['failed']
			end

      workbench :lines do
        notification_rule :all_line_ids, line_ids: []
        notification_rule :first_line, line_ids: [1]
        notification_rule :last_line, line_ids: [2]
      end
    end
  end

  let(:query) { Query::NotificationRule.new(workbench.notification_rules) }

  describe '#email' do
		let(:workbench) { context.workbench(:email) }

		context 'when target type is workbench' do
      let(:expected_scope) { context.notification_rules(:workbench) }

			it 'should return notification rule with workbench target type' do
				scope = query.email('abc').scope
				expect(scope).to match_array(expected_scope)
			end
		end

		context 'when target type is user' do
      let(:expected_scope) { workbench.notification_rules.where(target_type: ['user', 'workbench']) }

			before do
        nf = expected_scope.find_by(target_type: 'user')
				nf.update_columns(user_ids: [context.user(:last).id])
        nf.reload
			end

			it 'should return notification rule with user target type' do
				scope = query.email('test').scope
				expect(scope).to match_array(expected_scope)
			end
		end

		context 'when target type is external_email' do
      let(:expected_scope) { context.notification_rules(:external_email) }

			it 'should return notification rule with external_email target type' do
				scope = query.email('external').scope
				expect(scope).to match_array(expected_scope)
			end
		end
  end

  describe '#period' do
    let(:workbench) { context.workbench(:period) }
    let(:expected_scope) { context.notification_rules(:in_period) }

    it 'should return the notification rule with the overlapping period' do
      scope = query.in_period(Time.zone.today..Time.zone.today).scope
			expect(scope).to match_array(expected_scope)
    end
  end

  describe '#rule_type' do
    let(:workbench) { context.workbench(:rule_type) }
    let(:expected_scope) { [context.notification_rule(:block)] }

    it 'should return the notification type with the block rule_type' do
      scope = query.rule_type(['block']).scope
      expect(scope).to match_array(expected_scope)
    end
  end

  describe '#operation_statuses' do
    let(:workbench) { context.workbench(:operation_statuses) }
    let(:expected_scope) do
      [
        context.notification_rule(:all_statuses),
        context.notification_rule(:warning),
        context.notification_rule(:failed),
      ]
    end

    it 'should return the notification type that does not have any operation_statuses' do
      scope = query.operation_statuses(['warning', 'failed']).scope
      expect(scope).to match_array(expected_scope)
    end
  end

  describe '#lines' do
    let(:workbench) { context.workbench(:lines) }
    subject { query.lines(line_ids).scope }

    context 'when line_ids = [1]' do
      let(:line_ids) { [1] }
      let(:expected_scope) do
        [
          context.notification_rule(:all_line_ids),
          context.notification_rule(:first_line),
        ]
      end

      it 'should change scope' do
        is_expected.to match_array(expected_scope)
      end
    end

    context 'when line_ids contains empty string' do
      let(:line_ids) { [''] }
      let(:expected_scope) { workbench.notification_rules }

      it 'should not change scope' do
         is_expected.to match_array(expected_scope)
      end
    end

    context 'when line_ids is null' do
      let(:line_ids) { nil }
      let(:expected_scope) { workbench.notification_rules }

      it 'should not change scope' do
         is_expected.to match_array(expected_scope)
      end
    end

  end
end
