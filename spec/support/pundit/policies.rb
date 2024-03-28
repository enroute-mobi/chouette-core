require 'pundit/rspec'

module Pundit
  module RSpec
    module PolicyExampleGroup
      def self.included(base)
        base.metadata[:type] = :pundit_policy # monkey patch here
        base.extend Pundit::RSpec::DSL
        super
      end
    end
  end
end

module Support
  module Pundit
    module Policies
      def create_user_context(user, referential, workbench = nil)
        UserContext.new(user, referential: referential, workbench: workbench)
      end

      def finalise_referential
        referential.referential_suite_id = random_int
      end
    end

    module PoliciesMacros
      def self.extended into
        into.module_eval do
          subject { described_class }
          let( :user_context ) { create_user_context(user, referential)  }
          let( :referential )  { build_stubbed :referential }
          let( :user )         { build_stubbed :user }
        end
      end

      def with_user_permission(permission, &blk)
        it "with user permission #{permission.inspect}" do
          add_permissions(permission, to_user: user)
          blk.()
        end
      end
    end
  end
end

RSpec.configure do | c |
  # redefine pundit default configuration so we can claim ':policy' type
  c.instance_variable_get(:@include_modules).items_and_filters.delete_if do |i|
    i.first == Pundit::RSpec::PolicyExampleGroup
  end
  c.include Pundit::RSpec::PolicyExampleGroup, type: :pundit_policy

  require Rails.root.join('spec/support/controller_spec_helper')
  c.include ControllerSpecHelper::Permissions, type: :pundit_policy
  c.include Support::Pundit::Policies, type: :pundit_policy
  c.extend Support::Pundit::PoliciesMacros, type: :pundit_policy
end
