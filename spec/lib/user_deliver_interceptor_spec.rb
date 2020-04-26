RSpec.describe UserDeliverInterceptor do

  subject(:interceptor) { UserDeliverInterceptor.new(enabled: true) }

  let(:message) { Mail::Message.new to: ["first@example.com", "second@example.com"] }
  let(:email_address) { 'test@example.com' }

  describe '#delivering_email' do

    context "when the interceptor accepts the email" do
      before { allow(interceptor).to receive(:accept?).with(message).and_return true }

      it "doesn't cancel the message" do
        expect { interceptor.delivering_email(message) }.to_not change(message, :perform_deliveries)
      end

    end

    context "when the interceptor don't accept the email" do
      before { allow(interceptor).to receive(:accept?).with(message).and_return false }

      it "doesn't cancel the message" do
        expect { interceptor.delivering_email(message) }.to change(message, :perform_deliveries).to(false)
      end

    end

  end

  describe "#enabled?" do

    subject { interceptor.enabled? }

    context "when UserDeliverInterceptor is created with enabled: true" do
      it { is_expected.to be(true) }
    end

    context "when UserDeliverInterceptor is created with enabled: false" do
      let(:interceptor) { UserDeliverInterceptor.new(enabled: false) }
      it { is_expected.to be(false) }
    end

  end

  describe "#accept?" do

    subject { interceptor.accept?(message) }

    context "when interceptor isn't enabled?" do
      before { interceptor.enabled = false }
      it { is_expected.to be(false) }
    end

    context "when interceptor is enabled" do

      context "and all message recipients are accepted" do
        before { allow(interceptor).to receive(:accept_email_address?).and_return true }
        it { is_expected.to be(true) }
      end

      context "and one of message recipients isn't accepted" do
        before do
          allow(interceptor).to receive(:accept_email_address?).with(message.to.first).and_return true
          allow(interceptor).to receive(:accept_email_address?).with(message.to.second).and_return false
        end
        it { is_expected.to be(false) }
      end

      context "and all message recipients aren't accepted" do
        before { allow(interceptor).to receive(:accept_email_address?).and_return false }
        it { is_expected.to be(false) }
      end

    end

    context "when message uses only bcc recipients" do

      let(:message) { Mail::Message.new bcc: ["first@example.com", "second@example.com"] }

      before do
        allow(interceptor).to receive(:accept_email_address?).with(message.bcc.second).and_return true
      end

      it "checks bcc email addresses" do
        expect(interceptor).to receive(:accept_email_address?).with(message.bcc.first).and_return true
        expect(interceptor).to receive(:accept_email_address?).with(message.bcc.second).and_return true

        is_expected.to be(true)
      end

    end

    it "checks email adresses returned by #message_recipients" do
      expect(interceptor).to receive(:message_recipients).with(message).and_return [email_address]
      expect(interceptor).to receive(:accept_email_address?).with(email_address).and_return true

      is_expected.to be(true)
    end

  end

  describe '#message_recipients' do

    [ # to, bcc, expected
      [ nil, nil, [] ],
      [ [], [], [] ],
      [ "test@example.com", nil, [ "test@example.com" ] ],
      [ "test@example.com", "test@example.com", [ "test@example.com" ] ],
      [ nil, "test@example.com", [ "test@example.com" ] ],
      [ nil, ["test@example.com"], [ "test@example.com" ] ]
    ].each do |to, bcc, expected|
      it "returns #{expected.inspect} when to: #{to.inspect} and bcc: #{bcc.inspect}" do
        expect(subject.message_recipients(double "Message", to: to, bcc: bcc)).to eq(expected)
      end

    end




  end

  describe "#accept_email_address?" do

    subject { interceptor.accept_email_address? email_address }

    context "when email address is blacklisted" do
      before { allow(interceptor).to receive(:blacklisted?).with(email_address).and_return true }
      it { is_expected.to be(false) }
    end

    context "when email address isn't blacklisted" do
      before { allow(interceptor).to receive(:blacklisted?).with(email_address).and_return false }

      context "and is whitelisted" do
        before { allow(interceptor).to receive(:whitelisted?).with(email_address).and_return true }
        it { is_expected.to be(true) }
      end

      context "and isn't whitelisted" do
        before { allow(interceptor).to receive(:whitelisted?).with(email_address).and_return false }
        it { is_expected.to be(false) }
      end
    end

  end

  describe '#cancel' do

    it "change message perform_deliveries to false" do
      expect { interceptor.cancel(message) }.to change(message, :perform_deliveries).to(false)
    end

  end

  describe "#whitelisted?" do

    subject { interceptor.whitelisted? email_address }

    context "when whitelist is empty" do
      before { interceptor.whitelist = [] }
      it { is_expected.to be(true) }
    end

    context "when whitelist isn't empty" do
      before { interceptor.whitelist = 'not empty' }

      context "when whitelist matches the email address" do
        before { allow(UserDeliverInterceptor).to receive(:match?).with(interceptor.whitelist, email_address).and_return true }
        it { is_expected.to be(true) }
      end

      context "when whitelist doesn't match the email address" do
        before { allow(UserDeliverInterceptor).to receive(:match?).with(interceptor.whitelist, email_address).and_return false }
        it { is_expected.to be(false) }
      end

    end

  end

  describe "#blacklisted?" do

    subject { interceptor.blacklisted? email_address }

    context "when blacklist matches the email address" do
      before { allow(UserDeliverInterceptor).to receive(:match?).with(interceptor.blacklist, email_address).and_return true }
      it { is_expected.to be(true) }
    end

    context "when blacklist doesn't match the email address" do
      before { allow(UserDeliverInterceptor).to receive(:match?).with(interceptor.blacklist, email_address).and_return false }
      it { is_expected.to be(false) }
    end

  end

  describe ".match?" do

    [ # definition, email_address, expected
      [ "@domain", "test@domain", true ],
      [ "@domain", "test@otherdomain", false ],
      [ 'test@example.com', 'test@example.com', true ],
      [ 'test@example.com', ' test@example.com', false ],
      [ 'test@example.com', 'test@example.com ', false ],
      [ '', 'test@example.com', false ],
      [ /example/, "test@example.com", true ],
      [ /dummy/, "test@example.com", false ],
      [ [ '@domain' ], "test@domain", true ],
      [ [ '@otherdomain', '@domain' ], 'test@domain', true ],
      [ [], 'test@example.com', false ],
      [ :strange, 'test@example.com', false ],
    ].each do |definition, email_address, expected|
      it "#{expected ? "matches" : "doesn't match"} #{email_address} with this definition #{definition.inspect}" do
        expect(UserDeliverInterceptor.match? definition, email_address).to be(expected)
      end

    end

  end

  describe ".from_config" do

    it "uses Rails.application.config by default" do
      expect(Rails.application.config).to receive(:chouette_email_user).and_return(true)
      expect(UserDeliverInterceptor.from_config).to be_enabled
    end

    let(:config) { double "Rails config" }

    context "when config.chouette_email_user is false" do
      before { allow(config).to receive(:chouette_email_user).and_return(false) }

      it "returns a disabled interceptor" do
        expect(UserDeliverInterceptor.from_config(config)).to_not be_enabled
      end
    end

    context "when config.chouette_email_user is true" do
      before { allow(config).to receive(:chouette_email_user).and_return(true) }

      it "returns a enabled interceptor" do
        expect(UserDeliverInterceptor.from_config(config)).to be_enabled
      end

      it "blacklist and whitelist are empty by default" do
        expect(UserDeliverInterceptor.from_config(config)).to have_attributes(blacklist: [], whitelist: [])
      end

      context "when config.chouette_email_blacklist is defined" do
        let(:blacklist) { 'dummy' }
        before { allow(config).to receive(:chouette_email_blacklist).and_return(blacklist) }

        it "returns an interceptor with this blacklist" do
          expect(UserDeliverInterceptor.from_config(config)).to have_attributes(blacklist: blacklist)
        end
      end

      context "when config.chouette_email_whitelist is defined" do
        let(:whitelist) { 'dummy' }
        before { allow(config).to receive(:chouette_email_whitelist).and_return(whitelist) }

        it "returns an interceptor with this whitelist" do
          expect(UserDeliverInterceptor.from_config(config)).to have_attributes(whitelist: whitelist)
        end
      end
    end

  end
end
