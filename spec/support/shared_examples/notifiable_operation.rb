RSpec.shared_examples_for 'a notifiable operation' do
  let(:notification_target) { nil }

  before(:each) do
    workbench = subject.workbench_for_notifications
    3.times do
      workbench.organisation.users << create(:user)
    end
  end

  it 'should observe when finished' do
    expect(observer.instance).to receive(:after_update).exactly(:once)
    subject.status = 'successful'
    subject.save
  end

  context 'without notification_target' do
    before(:each) do
      subject.notification_target = nil
    end

    it 'should not schedule mailer when finished' do
      expect(mailer).to_not receive(:new)
      subject.status = 'successful'
      subject.save
      expect(subject.notified_recipients?).to be_falsy
    end

    it 'should not schedule mailer when not finished' do
      expect(mailer).to_not receive(:new)
      subject.status = 'running'
      subject.save
      expect(subject.notified_recipients?).to be_falsy
    end
  end

  context 'with notification_target set to user' do
    before(:each) do
      subject.notification_target = :user

      message_delivery = instance_double(ActionMailer::MessageDelivery)
      allow(message_delivery).to receive(:deliver_later)
    end

    it 'should schedule mailer when finished' do
      message_delivery = instance_double(ActionMailer::MessageDelivery)
      allow(message_delivery).to receive(:deliver_later)
      
      expect(mailer).to receive(:finished).with(subject.id, [user.email_recipient], 'successful').exactly(:once).and_return(message_delivery)
     
      subject.status = 'successful'
      subject.save
      expect(subject.notified_recipients?).to be_truthy
    end
  end

  context 'with notification_target set to workbench' do
    before(:each) do
      subject.notification_target = :workbench
    end

    it 'should schedule mailer when finished' do
      message_delivery = instance_double(ActionMailer::MessageDelivery)
      allow(message_delivery).to receive(:deliver_later)

      expect(mailer).to receive(:finished).with(subject.id, subject.workbench_for_notifications.users.map(&:email_recipient), 'successful').exactly(:once).and_return(message_delivery)
      subject.status = 'successful'
      subject.save
      expect(subject.notified_recipients?).to be_truthy
    end
  end

  describe '#notification_users' do
    context 'when notification_target is none' do
      it 'should return an empty array' do
        allow(subject).to receive(:notification_target) { 'none' }

        expect(subject.notification_users).to be_empty
      end
    end

    context 'when notification_target is user' do
      it 'should return a collection with only its user' do
        allow(subject).to receive(:notification_target) { 'user' }

        expect(subject.notification_users).to match_array([subject.user])
      end
    end

    context 'when notification_target is workbench' do
       it 'should return a collection with workbench\'s users' do
        allow(subject).to receive(:notification_target) { 'workbench' }

        expect(subject.notification_users).to match_array(subject.workbench_for_notifications.users)
      end
    end
  
    context 'when notification_target is workgroup' do
      it 'should return a collection with workbench\'s users' do
        allow(subject).to receive(:notification_target) { 'workgroup' }

        expect(subject.notification_users).to match_array(subject.workgroup_for_notifications.workbenches.map(&:users).flatten)
      end
    end
  end
end
