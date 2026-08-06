# frozen_string_literal: true

RSpec.describe NotificationRule, type: :model do
  subject(:notification_rule) { NotificationRule.new }

  it { is_expected.to belong_to(:workbench).required }

  it { is_expected.to validate_presence_of(:notification_type) }
  it do
    is_expected.to validate_numericality_of(:priority)
      .only_integer.is_greater_than_or_equal_to(1)
      .is_less_than_or_equal_to(1000)
  end

  it do
    is_expected.to enumerize(:notification_type)
      .in(:import, :merge, :aggregate, :source_retrieval, :publication, :scheduled_processing)
      .with_default(:import)
  end
  it { is_expected.to enumerize(:target_type).in(:user, :workbench, :external_email).with_default(:workbench) }
  it { is_expected.to enumerize(:rule_type).in(:notify, :block).with_default(:notify) }
  it { is_expected.to enumerize(:operation_statuses).in(:successful, :warning, :failed).with_multiple(true) }

  describe '#users' do
    it { is_expected.to allow_value([]).for(:users) }

    context 'when target_type is "user"' do
      let(:user) { Chouette.create { user }.user }

      before { subject.target_type = 'user' }

      it { is_expected.to allow_value([user]).for(:users) }
      it { is_expected.not_to allow_value([]).for(:users) }
    end
  end

  describe '#external_email' do
    it { is_expected.to allow_value('').for(:external_email) }

    context 'when target_type is "external_email"' do
      before { subject.target_type = 'external_email' }

      it { is_expected.to allow_value('user@text.ex').for(:external_email) }
      it { is_expected.not_to allow_value('').for(:external_email) }
      it { is_expected.not_to allow_value('not-an-email').for(:external_email) }
    end
  end

  describe '.for_operation' do
    subject { workbench.notification_rules.for_operation(operation) }

    let(:context) { Chouette.create { workbench } }
    let(:workbench) { context.workbench }

    let!(:scheduled_processing_rule) do
      workbench.notification_rules.create!(
        notification_type: 'scheduled_processing', target_type: 'workbench', priority: 10, operation_statuses: []
      )
    end
    let!(:import_rule) do
      workbench.notification_rules.create!(
        notification_type: 'import', target_type: 'workbench', priority: 10, operation_statuses: []
      )
    end

    context 'when the operation notification_type is scheduled_processing' do
      let(:operation) do
        Control::List::Run.new.tap do |run|
          allow(run).to receive(:notification_type).and_return('scheduled_processing')
        end
      end

      it 'selects the rules matching the operation notification_type' do
        is_expected.to contain_exactly(scheduled_processing_rule)
      end
    end

    context 'when the operation has no notification_type (an operation-triggered run)' do
      let(:operation) { Control::List::Run.new }

      it { is_expected.to be_empty }
    end
  end
end
