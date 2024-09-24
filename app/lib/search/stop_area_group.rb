# frozen_string_literal: true

module Search
  class StopAreaGroup < Base
    extend Enumerize

    # All search attributes
    attribute :text
    attribute :stop_areas
    attribute :stop_area_provider

    attr_accessor :workbench

    delegate :stop_area_referential, to: :workbench

    def query(scope)
      Query::StopAreaGroup.new(scope)
                          .text(text)
                          .stop_areas(stop_areas)
                          .stop_area_provider_id(stop_area_provider)
    end

    def candidate_stop_areas
      workbench.stop_area_referential.stop_areas.where(id: stop_areas)
    end

    def candidate_stop_area_providers
      stop_area_referential.stop_area_providers
    end

    class Order < ::Search::Order
      attribute :name, default: :desc
    end
  end
end
