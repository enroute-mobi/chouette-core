# frozen_string_literal: true

module DeviseControllerHelper
  extend ActiveSupport::Concern

  class_methods do
    def login_user
      before { login_user }
    end
  end

  def login_user
    @request.env['devise.mapping'] = Devise.mappings[:user]
    sign_in(current_user) # current_user is defined in Support::Policy::Lets
  end
end

RSpec.configure do |config|
  config.include Devise::Test::ControllerHelpers, type: :controller
  config.include DeviseControllerHelper, type: :controller
end
