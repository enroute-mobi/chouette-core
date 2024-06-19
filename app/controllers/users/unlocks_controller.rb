# frozen_string_literal: true

module Users
  class UnlocksController < Devise::UnlocksController
    before_action :not_found
  end
end
