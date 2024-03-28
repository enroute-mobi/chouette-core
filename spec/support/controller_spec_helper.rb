# frozen_string_literal: true

module ControllerSpecHelper
  extend ActiveSupport::Concern

  concerning :Permissions do # rubocop:disable Metrics/BlockLength
    class_methods do
      def with_permission(permission, &block)
        context "with permission #{permission}" do
          login_user
          before(:each) do
            @user.permissions << permission
            @user.save!
            sign_in @user
          end
          context('', &block) if block_given?
        end
      end

      def without_permission(permission, &block)
        context "without permission #{permission}" do
          login_user
          before(:each) do
            @user.permissions.delete permission
            @user.save!
            sign_in @user
          end
          context('', &block) if block_given?
        end
      end
    end

    def add_permissions(*permissions, to_user:, save: false)
      to_user.permissions ||= []
      to_user.permissions += permissions.flatten
      to_user.save if save
    end

    def remove_permissions(*permissions, from_user:, save: false)
      from_user.permissions ||= []
      from_user.permissions -= permissions.flatten
      from_user.save! if save
    end
  end

  concerning :Features do
    class_methods do
      def with_feature(feature, &block) # rubocop:disable Metrics/MethodLength
        context "with feature #{feature}" do
          login_user
          before(:each) do
            organisation = @user.organisation
            unless organisation.has_feature?(feature)
              organisation.features << feature
              organisation.save!
            end
            sign_in @user
          end
          context('', &block) if block_given?
        end
      end
    end
  end
end

RSpec.configure do |config|
  config.include ControllerSpecHelper, type: :controller
end
