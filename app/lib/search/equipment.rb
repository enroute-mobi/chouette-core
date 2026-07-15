# frozen_string_literal: true

module Search
  class Equipment < Base
    # All search attributes
    attribute :text
    attribute :stop_area_id
    attribute :stop_area_provider
    attribute :fixed, type: Boolean
    attribute :out_of_order, type: Boolean

    attr_accessor :workbench

    def searched_class
      ::Equipment
    end

    def query(scope)
      Query::Equipment.new(scope)
                      .text(text)
                      .stop_area_id(stop_area_id)
                      .stop_area_provider_id(stop_area_provider)
                      .fixed(fixed)
                      .out_of_order(out_of_order)
    end

    def candidate_stop_areas
      scope = workbench.stop_area_referential.stop_areas
      stop_area_id.present? ? scope.where(id: stop_area_id) : scope.none
    end

    def stop_area_provider_options
      workbench.stop_area_referential.stop_area_providers.pluck(:name, :id)
    end

    class Order < ::Search::Order
      attribute :name, default: :desc
    end
  end
end
