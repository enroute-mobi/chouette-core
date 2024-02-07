# frozen_string_literal: true

module Support
  module Policy
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
  config.include Support::Policy::Views, type: :view
  config.include Support::Policy::Decorators, type: :decorator
end
