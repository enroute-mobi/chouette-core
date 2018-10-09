require 'rails_helper'

RSpec.describe ImportObserver, type: :observer do
  let(:user) { create :user }
  let(:workbench_import) { create(:workbench_import, creator: user.name) }
  let(:referential) { create :referential }
 
  context "when ImportObserver is disabled" do
    before(:each) do
      allow(Rails.configuration)
        .to receive(:enable_subscriptions_notifications)
        .and_return( false )

      expect(Rails.configuration.enable_subscriptions_notifications).to be_falsy
    end

    it 'should not schedule mailer' do
      expect do 
        workbench_import.status = 'successful'
        workbench_import.save
      end.not_to change{ ActionMailer::Base.deliveries.count }
    end  

  end

  context 'when notification are enabled' do
    before(:each) do
      allow(Rails.configuration)
        .to receive(:enable_subscriptions_notifications)
        .and_return( true )

      expect(Rails.configuration.enable_subscriptions_notifications).to be_truthy
    end
    it 'should observe import finish' do
      expect(ImportObserver.instance).to receive(:after_update)
      workbench_import.status = 'successful'
      workbench_import.save
    end

    xit 'should schedule mailer on import finished' do
      expect do
        workbench_import.update(status: 'successful')
      end.to change { ActionMailer::Base.deliveries.count }.by(1)
    end
  end
end