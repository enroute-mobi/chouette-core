class ErrorsController < ApplicationController
  skip_before_action :authenticate_user!
  layout :layout

  include ErrorManagement

  protected

  def layout
    user_signed_in? ? 'application' : 'devise'
  end
end
