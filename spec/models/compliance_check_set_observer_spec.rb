require 'rails_helper'

RSpec.describe ComplianceCheckSetObserver, type: :observer do
  let(:user) { create :user, confirmed_at: Time.now }
  let(:notification_target) { nil }
  let(:context){ :manual }
  subject(:check_set) do
    create :compliance_check_set,
           parent: create(:netex_import),
           referential: create(:referential),
           context: context,
           notification_target: notification_target,
           user: user,
           metadata: { creator_id: create(:user).id }
  end
  let(:mailer) { ComplianceCheckSetMailer }
  let(:observer) { ComplianceCheckSetObserver }

  it_behaves_like 'a notifiable operation'

  context 'when context is automatic' do
    let(:context){ :automatic }

    it 'should observe when finished' do
      expect(observer.instance).to receive(:after_update).exactly(:once)
      subject.status = 'successful'
      subject.save
    end

    context 'with notification_target set to user' do
      before(:each) do
        subject.notification_target = :user
      end

      it 'should not schedule mailer when finished' do
        expect(ComplianceCheckSetMailer).to_not receive(:finished)
        subject.status = 'successful'
        subject.save
        expect(subject.notified_recipients?).to be_falsy
      end
    end

    context 'with notification_target set to workbench' do
      before(:each) do
        subject.notification_target = :workbench
      end

      it 'should not schedule mailer when finished' do
        expect(ComplianceCheckSetMailer).to_not receive(:finished)
        subject.status = 'successful'
        subject.save
        expect(subject.notified_recipients?).to be_falsy
      end
    end
  end
end
