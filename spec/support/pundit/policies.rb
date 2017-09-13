require 'pundit/rspec'

module Support
  module Pundit
    module Policies
      def add_permissions(*permissions, to_user:)
        to_user.permissions ||= []
        to_user.permissions += permissions.flatten
      end

      def create_user_context(user:, referential:)
        UserContext.new(user, referential: referential)
      end

      def remove_permissions(*permissions, from_user:, save: false)
        from_user.permissions -= permissions.flatten
        from_user.save! if save
      end

    end

    module PoliciesMacros
      def self.extended into
        into.module_eval do
          subject { described_class }
          let( :user_context ) { create_user_context(user: user, referential: referential)  }
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

    module FeaturePermissionMacros
      def with_permissions(*permissions, &blk)
        perms, options = permissions.partition{|x| String === x}
        context "with permissions #{perms.inspect}...", *options do
          before do
            add_permissions(*permissions, to_user: @user)
          end
          instance_eval(&blk)
        end
      end
    end
  end
end

RSpec.configure do | c |
  c.include Support::Pundit::Policies, type: :controller
  c.include Support::Pundit::Policies, type: :policy
  c.extend Support::Pundit::PoliciesMacros, type: :policy
  c.include Support::Pundit::Policies, type: :feature
  c.extend Support::Pundit::FeaturePermissionMacros, type: :feature
end
