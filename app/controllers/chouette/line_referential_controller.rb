# frozen_string_literal: true

module Chouette
  class LineReferentialController < WorkbenchController
    # To prevent a "chouette_" to be added to all its chidren
    resources_configuration[:self].delete(:route_prefix)

    belongs_to :line_referential, singleton: true

    def line_referential
      association_chain
      get_parent_ivar(:line_referential)
    end
    alias current_referential line_referential
    helper_method :current_referential
  end
end
