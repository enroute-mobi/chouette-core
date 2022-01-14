RSpec.describe NotificationCenter do
  subject(:notification_center) { NotificationCenter.new(workbench) }
  let(:workbench) { double }

  let(:default_notification_type) { :import }

  describe "#recipients" do
    let(:context) { Chouette.create { workbench } }
    let(:workbench) { context.workbench }

    context "when no period is specified" do
      subject { notification_center.recipients(default_notification_type) }

      it "include recipients from a notification rule with any period" do
        notification_rule = workbench.notification_rules.create!(
          notification_type: default_notification_type,
          target_type: "external_email",
          rule_type: "notify",
          period: Period.during(10.days),
          external_email: "dummy@example.com"
        )

        is_expected.to include(notification_rule.external_email)
      end
    end

    context "when no line is specified" do
      subject { notification_center.recipients(default_notification_type) }

      let(:context) do
        Chouette.create do
          workbench
          line
        end
      end
      let(:line) { context.line }

      it "include recipients from a notification rule with any line" do
        notification_rule = workbench.notification_rules.create!(
          notification_type: default_notification_type,
          target_type: "external_email",
          rule_type: "notify",
          line_ids: [line.id],
          external_email: "dummy@example.com"
        )

        is_expected.to include(notification_rule.external_email)
      end
    end
  end

end
