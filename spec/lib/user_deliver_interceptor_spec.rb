RSpec.describe UserDeliverInterceptor do

  describe 'delivering_email #accepts' do
    let(:message){ Mail::Message.new(to: ["test@randommailer.com"]) }

    describe 'allowed recipient' do
      before do
        allow(Rails.application.config).to receive(:chouette_email_blacklist){ [] }
      end

      it 'should pass' do
        expect(UserDeliverInterceptor.blacklisted?(message)).to be false
      end
    end

    describe 'blacklisted recipient' do
      before do
        allow(Rails.application.config).to receive(:chouette_email_blacklist){ ["@randommailer.com", "@pishingmailer.net", "noreply"] }
      end

      it 'should not pass' do
        expect(UserDeliverInterceptor.blacklisted?(message)).to be true
      end
    end

    describe 'allow mails config' do
      before do
        allow(Rails.application.config).to receive(:chouette_email_user){ true }
      end

      it 'should pass' do
        expect(UserDeliverInterceptor.prevent_mails?).to be false
      end
    end

    describe 'prevent mails config' do
      before do
        allow(Rails.application.config).to receive(:chouette_email_user){ false }
      end

      it 'should not pass' do
        expect(UserDeliverInterceptor.prevent_mails?).to be true
      end
    end

  end
end
