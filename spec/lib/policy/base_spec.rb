# frozen_string_literal: true

RSpec.describe Policy::Base do
  subject(:policy) { policy_class.new(resource) }

  let(:policy_class) { Policy::Base }
  let(:resource) { double }

  let(:resource_class) { double }

  describe '.authorize_by' do
    let(:strategy_class) { Class.new(Policy::Strategy::Base) }
    let(:policy_class) do
      Class.new(::Policy::Base) do
        def self.name
          'SomePolicy'
        end

        protected

        def _can?(_, *_)
          true
        end
      end
    end

    context 'without option' do
      before { policy_class.authorize_by(strategy_class) }

      context '#update?' do
        it 'invokes strategy and returns true when strategy succeeds' do
          expect_any_instance_of(strategy_class).to(receive(:apply).with(:update).and_return(true))
          expect(policy.update?).to be_truthy
        end

        it 'invokes strategy and returns false when strategy fails' do
          expect_any_instance_of(strategy_class).to(receive(:apply).with(:update).and_return(false))
          expect(policy.update?).to be_falsy
        end
      end

      context '#create?(resource_class)' do
        it 'invokes strategy' do
          expect_any_instance_of(strategy_class).to(receive(:apply).with(:create, resource_class).and_return(true))
          expect(policy.create?(resource_class)).to be_truthy
        end
      end

      context '#something?' do
        it 'invokes strategy' do
          expect_any_instance_of(strategy_class).to(receive(:apply).with(:something).and_return(true))
          expect(policy.something?).to be_truthy
        end
      end

      context '#something?(resource_class)' do
        it 'invokes strategy' do
          expect_any_instance_of(strategy_class).to(receive(:apply).with(:something, resource_class).and_return(true))
          expect(policy.something?(resource_class)).to be_truthy
        end
      end
    end

    context 'with only option' do
      before { policy_class.authorize_by(strategy_class, only: %i[update something]) }

      it 'invokes strategy for actions in only' do
        allow_any_instance_of(strategy_class).to receive(:apply).with(anything).and_return(false)
        expect(policy.update?).to be_falsy
        expect(policy.something?).to be_falsy
      end

      it 'does not invoke strategy for actions not in only' do
        expect_any_instance_of(strategy_class).not_to receive(:apply)
        expect(policy.destroy?).to be_truthy
        expect(policy.nothing?).to be_truthy
      end
    end
  end

  describe '#update?' do
    subject { policy.update? }

    it { is_expected.to be_falsy }

    it 'invokes _update? method' do
      expect(policy).to receive(:around_can).with(:update).and_call_original
      expect(policy).to receive(:_update?).and_return(true)
      is_expected.to be_truthy
    end
  end

  describe '#edit?' do
    subject { policy.edit? }

    it { is_expected.to be_falsy }

    it 'is an alias of #update?' do
      expect(policy).to receive(:around_can).with(:update).and_call_original
      expect(policy).to receive(:_update?).and_return(true)
      is_expected.to be_truthy
    end
  end

  describe '#destroy' do
    subject { policy.destroy? }

    it { is_expected.to be_falsy }

    it 'invokes _destroy? method' do
      expect(policy).to receive(:around_can).with(:destroy).and_call_original
      expect(policy).to receive(:_destroy?).and_return(true)
      is_expected.to be_truthy
    end
  end

  describe '#create?(resource_class)' do
    subject { policy.create?(resource_class) }

    it { is_expected.to be_falsy }

    it 'invokes _create? method with :create action and given resource class' do
      expect(policy).to receive(:around_can).with(:create, resource_class).and_call_original
      expect(policy).to receive(:_create?).with(resource_class).and_return(true)
      is_expected.to be_truthy
    end
  end

  describe 'new?(resource_class)' do
    subject { policy.create?(resource_class) }

    it { is_expected.to be_falsy }

    it 'is an alias of #create?' do
      expect(policy).to receive(:around_can).with(:create, resource_class).and_call_original
      expect(policy).to receive(:_create?).with(resource_class).and_return(true)
      is_expected.to be_truthy
    end
  end

  describe '#can?' do
    subject { policy.can?(:something) }

    it { is_expected.to be_falsy }

    it 'invokes _can? method with :something' do
      expect(policy).to receive(:around_can).with(:something).and_call_original
      expect(policy).to receive(:_can?).with(:something).and_return(true)
      is_expected.to be_truthy
    end
  end

  describe '#something?' do
    subject { policy.something? }

    it { is_expected.to be_falsy }

    it 'invokes can? method with :something action' do
      expect(policy).to receive(:can?).with(:something).and_call_original
      expect(policy).to receive(:_can?).with(:something).and_return(true)
      is_expected.to be_truthy
    end
  end

  describe '#something?(resource_class)' do
    subject { policy.something?(resource_class) }

    it { is_expected.to be_falsy }

    it 'invokes can? method with :something action and given resource class' do
      expect(policy).to receive(:can?).with(:something, resource_class).and_call_original
      expect(policy).to receive(:_can?).with(:something, resource_class).and_return(true)
      is_expected.to be_truthy
    end
  end
end

RSpec.describe Support::Policy::Policy::Matchers do
  # rubocop:disable Style/SingleLineMethods
  let(:strategy_class) { Class.new(Policy::Strategy::Base) { def self.name; 'SomeStrategy'; end } }
  # rubocop:enable Style/SingleLineMethods
  let(:wrong_strategy_class) { Class.new(Policy::Strategy::Base) }

  describe 'applies_strategy' do
    include Support::Policy::Policy

    let(:policy_enable_strategies) { true }

    # rubocop:disable Style/SingleLineMethods
    let(:policy_class) { Class.new(Policy::Base) { def self.name; 'SomePolicy'; end } }
    # rubocop:enable Style/SingleLineMethods
    let(:policy) { policy_class.new(resource) }

    subject { policy.update? }

    it 'fails when there is no strategy' do
      expect { applies_strategy(strategy_class) }.to raise_error(RSpec::Expectations::ExpectationNotMetError)
    end

    context 'when policy has a strategy' do
      before { policy_class.authorize_by(strategy_class) }

      it 'succeeds with the same strategy' do
        expect { applies_strategy(strategy_class) }.not_to raise_error
      end

      it 'succeeds with the same strategy and correct args' do
        expect { applies_strategy(strategy_class, :update) }.not_to raise_error
      end

      it 'fails with the same strategy but wrong args' do
        expect { applies_strategy(strategy_class, :create) }.to raise_error(RSpec::Expectations::ExpectationNotMetError)
      end

      it 'fails with a different strategy' do
        expect { applies_strategy(wrong_strategy_class) }.to raise_error(RSpec::Expectations::ExpectationNotMetError)
      end

      context 'when policy_enable_strategies is false' do
        let(:policy_enable_strategies) { false }

        it 'succeeds with the same strategy' do
          expect { applies_strategy(strategy_class) }.not_to raise_error
        end

        it 'fails with a different strategy' do
          expect { applies_strategy(wrong_strategy_class) }.to raise_error(RSpec::Expectations::ExpectationNotMetError)
        end
      end
    end

    it 'succeeds with the same strategy when policy has a strategy with only' do
      policy_class.authorize_by(strategy_class, only: %i[update])
      expect { applies_strategy(strategy_class) }.not_to raise_error
    end

    it 'succeeds when policy has an always failing strategy' do
      fail_strategy_class = Class.new(Policy::Strategy::Base) do
        def apply(_action, *_args)
          false
        end
      end
      policy_class.authorize_by(fail_strategy_class)
      policy_class.authorize_by(strategy_class)
      expect { applies_strategy(strategy_class) }.not_to raise_error
    end
  end

  describe described_class::ApplyStrategy do
    let(:args) { [] }

    subject(:matcher) { described_class.new(strategy_class, args) }

    describe '#description' do
      subject { matcher.description }

      it { is_expected.to eq('apply strategy SomeStrategy') }

      context 'with args' do
        let(:args) { [:update] }

        it { is_expected.to eq('apply strategy SomeStrategy with [:update]') }
      end
    end

    describe '#failure_message' do
      subject { matcher.failure_message }

      it { is_expected.to eq('Expected to apply strategy SomeStrategy but did not') }

      context 'with args' do
        let(:args) { [:update] }

        it { is_expected.to eq('Expected to apply strategy SomeStrategy with [:update] but did not') }
      end
    end
  end

  describe 'does_not_apply_strategy' do
    include Support::Policy::Policy

    let(:policy_enable_strategies) { true }

    # rubocop:disable Style/SingleLineMethods
    let(:policy_class) { Class.new(Policy::Base) { def self.name; 'SomePolicy'; end } }
    # rubocop:enable Style/SingleLineMethods
    let(:policy) { policy_class.new(resource) }

    subject { policy.update? }

    it 'fails when there is no strategy' do
      expect { does_not_apply_strategy(strategy_class) }.not_to raise_error
    end
  end

  describe described_class::NotApplyStrategy do
    let(:args) { [] }

    subject(:matcher) { described_class.new(strategy_class, args) }

    describe '#description' do
      subject { matcher.description }

      it { is_expected.to eq('not apply strategy SomeStrategy') }
    end

    describe '#failure_message' do
      subject { matcher.failure_message }

      it { is_expected.to eq('Expected to not apply strategy SomeStrategy but did') }
    end
  end
end
