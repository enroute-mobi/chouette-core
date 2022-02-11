# frozen_string_literal: true

RSpec.describe Chouette::Config do
  let(:environment) { { 'RAILS_ENV' => 'test' } }
  let(:config) { Chouette::Config.new environment }

  def self.with_rails_env(rails_env, &block)
    context "in #{rails_env}" do
      before { environment['RAILS_ENV'] = rails_env.to_s }
      class_exec(&block)
    end
  end

  def self.with_env(env, &block)
    description = env.map { |k, v| "#{k} is '#{v}'" }.to_sentence
    context "when #{description}" do
      before { env.each { |k, v| environment[k.to_s] = v.to_s }  }
      class_exec(&block)
    end
  end

  describe '#subscriotion' do
    subject(:subscription) { config.subscription }

    describe '#enabled?' do
      subject { subscription.enabled? }

      with_rails_env :development do
        it { is_expected.to be_truthy }
      end

      with_rails_env :test do
        it { is_expected.to be_truthy }
      end

      with_rails_env :production do
        it { is_expected.to be_falsy }

        with_env ACCEPT_USER_CREATION: 'true' do
          it { is_expected.to be_truthy }
        end

        with_env CHOUETTE_SUBSCRIPTION_ENABLED: 'true' do
          it { is_expected.to be_truthy }
        end

        with_env CHOUETTE_SUBSCRIPTION_ENABLED: 'false' do
          it { is_expected.to be_falsy }
        end
      end
    end

    describe "#notification_recipients" do
      subject { subscription.notification_recipients }

      it { is_expected.to eq([])}

      with_env CHOUETTE_SUBSCRIPTION_NOTIFICATION_RECIPIENTS: 'foo@example.com' do
        it { is_expected.to contain_exactly('foo@example.com') }
      end

      with_env CHOUETTE_SUBSCRIPTION_NOTIFICATION_RECIPIENTS: 'foo@example.com,bar@example.com' do
        it { is_expected.to contain_exactly('foo@example.com', 'bar@example.com') }
      end
    end

  end

end
