# frozen_string_literal: true

RSpec.describe SubscriptionMailer do

  describe ".recipients" do
    subject { SubscriptionMailer.recipients }

    context "when Chouette::Config.subscription.recipients is ['foo@example.com']" do
      before do
        allow(Chouette::Config.subscription).to receive(:notification_recipients).
                                                  and_return(['foo@example.com'])
      end

      it { is_expected.to contain_exactly('foo@example.com') }
    end
  end

  describe ".enabled?" do
    subject { SubscriptionMailer.enabled? }

    context "when recipients is empty" do
      before { allow(SubscriptionMailer).to receive(:recipients).and_return([]) }
      it { is_expected.to be_falsy }
    end

    context "when recipients is ['foo@example.com']" do
      before { allow(SubscriptionMailer).to receive(:recipients).and_return(['foo@example.com']) }
      it { is_expected.to be_truthy }
    end
  end
end
