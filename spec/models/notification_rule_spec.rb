
RSpec.describe NotificationRule, type: :model do
  subject { build(:notification_rule) }

  it { should belong_to(:workbench) }
  
  it { should validate_presence_of(:workbench) }
  it { should validate_presence_of(:notification_type) }
  it { should validate_presence_of(:period) }
  it { should validate_numericality_of(:priority).only_integer.is_greater_than_or_equal_to(1).is_less_than_or_equal_to(1000) }

  it { should enumerize(:notification_type).in(:hole_sentinel, :import, :merge).with_default(:hole_sentinel) }
  it { should enumerize(:target_type).in(:user, :workbench, :external_email).with_default(:workbench) }
  it { should enumerize(:rule_type).in(:notify, :block).with_default(:block) }
  it { should enumerize(:operation_statuses).in(:successful, :warning, :failed).with_multiple(true) }
end
