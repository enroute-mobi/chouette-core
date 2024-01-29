# frozen_string_literal: true

module Chouette
  class TopologicReferentialController < WorkbenchController
    # To prevent a "chouette_" to be added to all its chidren
    resources_configuration[:self].delete(:route_prefix)

    belongs_to :shape_referential, singleton: true

    def shape_referential
      association_chain
      get_parent_ivar(:shape_referential)
    end
    alias current_referential shape_referential
    helper_method :current_referential
  end
end
