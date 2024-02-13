# frozen_string_literal: true

module Support
  module Policy
    module Policy
      extend ActiveSupport::Concern

      concerning :Lets do
        included do
          let(:resource) { double }

          let(:policy_context_class) { ::Policy::Context::Empty }
          let(:policy_context_provider) { double }
          let(:policy_context) { policy_context_class.from(policy_context_provider) }
        end
      end

      included do
        subject(:policy) { described_class.new(resource, context: policy_context) }

        let(:policy_enable_strategies) { false }
        before { allow(policy).to receive(:apply_strategies_for).and_return(true) unless policy_enable_strategies }
      end

      module Matchers
        extend ActiveSupport::Concern

        def applies_strategy(strategy_class, *args)
          expect(strategy_applied?(strategy_class, *args)).to ApplyStrategy.new(strategy_class, args)
        end

        def does_not_apply_strategy(strategy_class, *args)
          expect(strategy_applied?(strategy_class, *args)).to NotApplyStrategy.new(strategy_class, args)
        end

        private

        def strategy_applied?(strategy_class, *args) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
          RSpec::Mocks.space.proxy_for(policy).remove_stub(:apply_strategies_for) unless policy_enable_strategies

          success = false
          allow(policy).to receive(:strategies).and_return(
            policy.strategies.transform_values do |v|
              v.map do |s|
                if s.class == strategy_class # rubocop:disable Style/ClassEqualityComparison
                  double(s.class.name).tap do |dbl|
                    allow(dbl).to receive(:apply) do |*dbl_args|
                      success = true if args.empty? || dbl_args == args
                      true
                    end
                  end
                else
                  double(s.class.name, apply: true)
                end
              end
            end
          )

          subject

          success
        end

        class ApplyStrategy
          def initialize(strategy_class, args)
            @strategy_class = strategy_class
            @args = args
          end

          def description
            description = "apply strategy #{@strategy_class.name}"
            description += " with #{@args.inspect}" if @args.any?
            description
          end

          def matches?(success)
            success
          end

          def failure_message
            failure_message = +"Expected to apply strategy #{@strategy_class.name}"
            failure_message << " with #{@args.inspect}" if @args.any?
            failure_message << ' but did not'
            failure_message
          end

          private

          def matches_only_array?(actions)
            ::RSpec::Matchers::BuiltIn::ContainExactly.new(@options[:only] || [nil]).matches?(actions)
          end
        end

        class NotApplyStrategy < ApplyStrategy
          def description
            "not #{super}"
          end

          def matches?(success)
            !success
          end

          def failure_message
            failure_message = +"Expected to not apply strategy #{@strategy_class.name}"
            failure_message << " with #{@args.inspect}" if @args.any?
            failure_message << ' but did'
            failure_message
          end
        end
      end
      include Matchers
    end

    module PolicyStrategy
      extend ActiveSupport::Concern

      include Policy::Lets

      included do
        let(:policy) { double(resource: resource, context: policy_context) }

        subject(:strategy) { described_class.new(policy) }
      end
    end

    module Lets
      extend ActiveSupport::Concern

      included do
        let(:permissions) { nil }
        let(:features) { [] }
        let(:current_user) { create :user, permissions: permissions, organisation: organisation }

        let(:current_workgroup) { current_workbench.workgroup }
        let(:current_workbench) { create :workbench, organisation: organisation }
        let(:current_referential) { referential || build_stubbed(:referential, organisation: organisation) }

        let(:policy_context_class) { ::Policy::Context::Empty }
        let(:policy_authorizer) do
          ::Policy::Authorizer::Controller.new(nil).tap do |authorizer|
            allow(authorizer).to receive(:context).and_return(policy_context_class.from(self))
          end
        end
      end
    end

    module Views
      extend ActiveSupport::Concern

      include Lets

      included do
        before do
          allow(view).to receive(:current_user) { current_user }
          allow(view).to receive(:current_organisation).and_return(organisation)
          allow(view).to receive(:current_workgroup).and_return(current_workgroup)
          allow(view).to receive(:current_workbench).and_return(current_workbench)
          allow(view).to receive(:has_feature?) { |f| features.include?(f) }
          allow(view).to receive(:user_signed_in?).and_return true
          allow(view).to receive(:policy) do |resource|
            policy_authorizer.policy(resource)
          end
          allow(view).to receive(:resource_policy) do
            view.policy(view.resource)
          end
        end
      end
    end

    module Decorators
      extend ActiveSupport::Concern

      include Lets

      included do
        before do
          allow(decorator.h).to receive(:policy) do |resource|
            policy_authorizer.policy(resource)
          end
          allow_any_instance_of(AF83::Decorator::Link).to receive(:check_feature) { |f| features.include?(f) }
        end
      end
    end
  end
end

RSpec.configure do |config|
  config.include Support::Policy::Policy, type: :policy
  config.include Support::Policy::PolicyStrategy, type: :policy_strategy
  config.include Support::Policy::Views, type: :view
  config.include Support::Policy::Decorators, type: :decorator
end
