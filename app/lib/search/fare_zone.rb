# frozen_string_literal: true

module Search
  class FareZone < Base
    attr_accessor :workbench

    # All search attributes
    attribute :name
    attribute :fare_provider_id

    def searched_class
      ::Fare::Zone
    end

    def query(scope)
      Query::FareZone.new(scope)
                         .name(name)
                         .fare_provider_id(fare_provider_id)
    end

    def candidate_fare_providers
      workbench.fare_providers.order(:name)
    end

    class Order < ::Search::Order
      attribute :name
      attribute :created_at, default: :desc
    end
  end
end
