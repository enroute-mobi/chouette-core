RSpec.describe NotifiableOperationObserver do
  let(:context) do
    Chouette.create { workbench }
  end
  let(:workbench) { context.workbench }

  subject { NotifiableOperationObserver.instance }

  describe "after_update" do
    [
      Export::Gtfs, Export::Netex, Export::NetexGeneric,
      Import::Workbench, Merge
    ].each do |operation_class|
      context "when operation is an #{operation_class}" do
        let(:operation) { operation_class.new workbench: workbench }
        let(:notification_center) { operation.workbench.notification_center }

        %w{successful failed}.each do |status|
          context "when status is #{status}" do
            before { operation.status = status }

            it "sends notification via Workbench NotificationCenter" do
              expect(notification_center).to receive(:notify).with(operation)
              subject.after_update(operation)
            end
          end
        end

        %w{running}.each do |status|
          context "when status is #{status}" do
            before { operation.status = status }

            it "doesn't send notification via Workbench NotificationCenter" do
              expect(notification_center).to_not receive(:notify).with(operation)
              subject.after_update(operation)
            end
          end
        end

        context "when notified_recipients_at is defined" do
          before do
            operation.status = :successful
            operation.notified_recipients_at = Time.zone.now
          end

          it "doesn't send notification via Workbench NotificationCenter" do
            expect(notification_center).to_not receive(:notify).with(operation)
            subject.after_update(operation)
          end
        end
      end
    end
  end

  context "when operation is an Aggregate" do
    let(:workgroup) { context.workgroup }

    let(:operation)  { Aggregate.new }
    before { allow(operation).to receive(:workbench_for_notifications).and_return(workbench) }

    let(:notification_center) { operation.workbench_for_notifications.notification_center }

    %w{successful failed}.each do |status|
      context "when status is #{status}" do
        before { operation.status = status }

        it "sends notification via Workbench NotificationCenter" do
          expect(notification_center).to receive(:notify).with(operation)
          subject.after_update(operation)
        end
      end
    end

    %w{running}.each do |status|
      context "when status is #{status}" do
        before { operation.status = status }

        it "doesn't send notification via Workbench NotificationCenter" do
          expect(notification_center).to_not receive(:notify).with(operation)
          subject.after_update(operation)
        end
      end
    end
  end
end
