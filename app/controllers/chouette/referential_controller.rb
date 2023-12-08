# frozen_string_literal: true

module Chouette
  class ReferentialController < ResourceController
    # To prevent a "chouette_" to be added to all its chidren
    resources_configuration[:self].delete(:route_prefix)
  end
end
