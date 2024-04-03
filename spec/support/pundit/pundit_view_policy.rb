module Pundit
  module PunditViewPolicy
    def self.included into
      into.let(:pundit_user){ UserContext.new(current_user, referential: current_referential) }
      into.before do
        allow(view).to receive(:pundit_user) { pundit_user }
        allow(view).to receive(:policy) do |instance|
          ::Policy::Legacy.new(pundit_user, instance)
        end
        allow(view).to receive(:resource_policy) do
          view.policy(view.resource)
        end
      end
    end
  end

  module PunditDecoratorPolicy
    def self.included into
      into.let(:user_context) { UserContext.new(current_user, referential: current_referential) }

      into.before do
        allow(decorator.h).to receive(:policy) do |instance|
          ::Policy::Legacy.new(user_context, instance)
        end
      end
    end
  end
end
