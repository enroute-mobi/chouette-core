module Pundit
  module PunditViewPolicy
    def self.included into
      into.let(:permissions){ nil }
      into.let(:current_referential){ referential || build_stubbed(:referential, organisation: organisation) }
      into.let(:current_user){ create :user, permissions: permissions, organisation: organisation }
      into.let(:pundit_user){ UserContext.new(current_user, referential: current_referential) }
      into.let(:current_workbench) { create :workbench, organisation: organisation}
      into.before do
        allow(view).to receive(:pundit_user) { pundit_user }
        allow(view).to receive(:current_user) { current_user }
        allow(view).to receive(:current_organisation).and_return(organisation)
        allow(view).to receive(:current_workbench).and_return(current_workbench)
        allow(view).to receive(:current_workgroup).and_return(current_workbench.workgroup)
        allow(view).to receive(:has_feature?){ |f| respond_to?(:features) && features.include?(f)}
        allow(view).to receive(:user_signed_in?).and_return true
        allow(view).to receive(:policy) do |instance|
          ::Pundit.policy pundit_user, instance
        end
      end
    end
  end
end

RSpec.configure do |config|
  config.include Pundit::PunditViewPolicy, type: :view
end
