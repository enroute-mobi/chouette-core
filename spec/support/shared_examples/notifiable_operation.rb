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
    end

    it 'should schedule mailer when finished' do
      expect(mailer).to receive(:finished).with(subject.id, [user.email_recipient], 'successful').exactly(:once)
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
      expect(mailer).to receive(:finished).with(subject.id, subject.workbench_for_notifications.users.map(&:email_recipient), 'successful').exactly(:once)
      subject.status = 'successful'
      subject.save
      expect(subject.notified_recipients?).to be_truthy
    end
  end
end
