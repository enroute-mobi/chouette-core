# frozen_string_literal: true

module Queries
  module ByObjectidOrRegistrationNumber
    extend ActiveSupport::Concern

    included do
      argument :objectid, String, required: false
      argument :registration_number, String, required: false
    end

    protected

    def scope(**kwargs)
      scope = super(**kwargs)

      arguments = kwargs.slice(:objectid, :registration_number).compact
      scope = scope.where(arguments) if arguments.any?

      scope
    end
  end
end
