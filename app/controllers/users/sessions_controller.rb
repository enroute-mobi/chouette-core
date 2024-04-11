# frozen_string_literal: true

module Users
  class SessionsController < Devise::SessionsController
    include SamlSessionsSupport

    before_action :sign_in_first_step, only: %i[create]

    private

    def sign_in_first_step
      user_params = sign_in_params
      return unless user_params[:email].present? && user_params[:password].blank?

      self.resource = resource_class.find_for_database_authentication(user_params)

      if resource&.must_sign_in_with_saml?
        sign_in_with_saml
      else
        render_sign_in_second_step
      end
    end

    # copied from Devise::SessionsController#new (this code has to be updated every time the gem is updated)
    def render_sign_in_second_step
      new_resource = resource_class.new(sign_in_params)
      new_resource.organisation = resource.organisation if resource
      self.resource = new_resource
      clean_up_passwords(resource)
      render :new
    end
  end
end
