RSpec.describe NotificationCenter do
  subject(:notification_center) { NotificationCenter.new(workbench) }
  let(:workbench) { double }

  let(:default_notification_type) { :import }

  describe '#recipients' do
    let(:context) { Chouette.create { workbench } }
    let(:workbench) { context.workbench }

    context 'when no period is specified' do
      subject { notification_center.recipients(default_notification_type) }

      it 'include recipients from a notification rule with any period' do
        notification_rule = workbench.notification_rules.create!(
          notification_type: default_notification_type,
          target_type: 'external_email',
          rule_type: 'notify',
          period: Period.during(10.days),
          external_email: 'dummy@example.com'
        )

        is_expected.to include(notification_rule.external_email)
      end
    end

    context 'when no line is specified' do
      subject { notification_center.recipients(default_notification_type) }

      let(:context) do
        Chouette.create do
          workbench
          line
        end
      end
      let(:line) { context.line }

      it 'include recipients from a notification rule with any line' do
        notification_rule = workbench.notification_rules.create!(
          notification_type: default_notification_type,
          target_type: 'external_email',
          rule_type: 'notify',
          line_ids: [line.id],
          external_email: 'dummy@example.com'
        )

        is_expected.to include(notification_rule.external_email)
      end
    end
  end

  describe NotificationCenter::LegacyNotification do
    subject(:notification) { described_class.new(operation) }

    let(:operation) { Merge.new }
    before { allow(operation).to receive(:update_column) }

    describe '#current_status' do
      subject { notification.current_status }
      context 'when operation status is successful' do
        before { operation.status = :successful }
        it { is_expected.to eq(:successful) }
      end
    end

    describe '#deliver' do
      context 'when operation is already notified' do
        before do
          operation.notified_recipients_at = Time.zone.now
          allow(notification).to receive(:recipients).and_return(%w[dummy@example.com])
        end

        it 'should not send mail' do
          expect(notification.mailer).to_not receive(:finished)
          notification.deliver
        end
      end
    end
  end

  describe NotificationCenter::Notification do
    subject(:notification) { described_class.new(operation) }

    let(:operation) { Source::Retrieval.new }

    describe '#current_status' do
      subject { notification.current_status }
      context 'when operation user status is successful' do
        before { operation.user_status = :successful }
        it { is_expected.to eq(:successful) }
      end
    end

    describe '#deliver' do
      before do
        allow(notification).to receive(:recipients).and_return(%w[dummy@example.com])
      end

      it 'should send mail' do
        expect(notification.mailer).to receive(:finished).and_return(double(deliver_later: true))
        notification.deliver
      end
    end
  end
end
