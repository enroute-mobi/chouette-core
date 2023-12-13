# frozen_string_literal: true

class ErrorsController < ApplicationController
  layout :layout

  include ErrorManagement

  protected

  def layout
    user_signed_in? ? 'application' : 'devise'
  end
end
