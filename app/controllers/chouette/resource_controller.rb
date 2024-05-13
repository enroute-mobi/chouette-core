# frozen_string_literal: true

module Chouette
  class ResourceController < UserController
    inherit_resources

    # To prevent a "chouette_" to be added to all its chidren
    resources_configuration[:self].delete(:route_prefix)

    include PolicyChecker

    private

    def begin_of_association_chain
      current_user
    end
  end
end
