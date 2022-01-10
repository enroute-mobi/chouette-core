RSpec.describe NotificationRule, type: :model do
  let(:context) do
    Chouette.create { notification_rule }
  end
  subject(:notification_rule) { context.notification_rule }

  it { is_expected.to belong_to(:workbench) }

  it { is_expected.to validate_presence_of(:workbench) }
  it { is_expected.to validate_presence_of(:notification_type) }
  it { is_expected.to validate_numericality_of(:priority).only_integer.is_greater_than_or_equal_to(1).is_less_than_or_equal_to(1000) }

  it { is_expected.to enumerize(:notification_type).in(:hole_sentinel, :import, :merge, :aggregate).with_default(:import) }
  it { is_expected.to enumerize(:target_type).in(:user, :workbench, :external_email).with_default(:workbench) }
  it { is_expected.to enumerize(:rule_type).in(:notify, :block).with_default(:block) }
  it { is_expected.to enumerize(:operation_statuses).in(:successful, :warning, :failed).with_multiple(true) }
end
