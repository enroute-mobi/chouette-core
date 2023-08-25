# frozen_string_literal: true

RSpec.describe NotificationRule, type: :model do
  subject(:notification_rule) { NotificationRule.new }

  it { is_expected.to belong_to(:workbench) }

  it { is_expected.to validate_presence_of(:workbench) }
  it { is_expected.to validate_presence_of(:notification_type) }
  it do
    is_expected.to validate_numericality_of(:priority)
      .only_integer.is_greater_than_or_equal_to(1)
      .is_less_than_or_equal_to(1000)
  end

  it do
    is_expected.to enumerize(:notification_type)
      .in(:import, :merge, :aggregate, :source_retrieval, :publication)
      .with_default(:import)
  end
  it { is_expected.to enumerize(:target_type).in(:user, :workbench, :external_email).with_default(:workbench) }
  it { is_expected.to enumerize(:rule_type).in(:notify, :block).with_default(:block) }
  it { is_expected.to enumerize(:operation_statuses).in(:successful, :warning, :failed).with_multiple(true) }

  describe '.covering' do
    subject { NotificationRule.covering(period) }
    let(:period) { Period.during(10.days) }

    let(:context) { Chouette.create { workbench } }
    let(:notification_rule) { context.workbench.notification_rules.create! }

    context 'when a NotificationRule has no period' do
      before { notification_rule.update period: nil }
      it { is_expected.to include(notification_rule) }
    end

    context 'when a NotificationRule period is the same than given one' do
      before { notification_rule.update period: period }
      it { is_expected.to include(notification_rule) }
    end

    context 'when a NotificationRule period is after the given one' do
      let(:after_period) { Period.after(period).during(10.days) }
      before { notification_rule.update period: after_period }

      it { is_expected.to_not include(notification_rule) }
    end

    context 'when a NotificationRule period is after the given one' do
      let(:before_period) { Period.before(period).during(10.days) }
      before { notification_rule.update period: before_period }

      it { is_expected.to_not include(notification_rule) }
    end

    context 'when a NotificationRule period starts during the given period and ends after' do
      before { notification_rule.update period: Period.from(period.middle).until(period.to.tomorrow) }
      it { is_expected.to_not include(notification_rule) }
    end

    context 'when a NotificationRule period starts before and ends during the given period' do
      before { notification_rule.update period: Period.from(period.from.yesterday).until(period.middle) }
      it { is_expected.to_not include(notification_rule) }
    end
  end
end
