# frozen_string_literal: true

module Search
  class Equipement < Base
    # All search attributes
    attribute :text
    attribute :stop_area_id
    attribute :shape_provider_id
    attribute :fixed, type: Boolean
    attribute :out_of_order, type: Boolean

    attr_accessor :workbench

    def searched_class
      ::Equipement
    end

    def query(scope)
      Query::Equipement.new(scope)
                       .text(text)
                       .stop_area_id(stop_area_id)
                       .shape_provider_id(shape_provider_id)
                       .fixed(fixed)
                       .out_of_order(out_of_order)
    end

    def candidate_stop_areas
      scope = workbench.stop_area_referential.stop_areas
      stop_area_id.present? ? scope.where(id: stop_area_id) : scope.none
    end

    def shape_provider_options
      workbench.shape_referential.shape_providers.pluck(:short_name, :id)
    end

    class Order < ::Search::Order
      attribute :name, default: :desc
    end
  end
end
