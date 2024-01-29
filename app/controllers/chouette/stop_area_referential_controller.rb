# frozen_string_literal: true

module Chouette
  class StopAreaReferentialController < WorkbenchController
    # To prevent a "chouette_" to be added to all its chidren
    resources_configuration[:self].delete(:route_prefix)

    belongs_to :stop_area_referential, singleton: true

    def stop_area_referential
      association_chain
      get_parent_ivar(:stop_area_referential)
    end
    alias current_referential stop_area_referential
    helper_method :current_referential
  end
end
