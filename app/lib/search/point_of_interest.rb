module Search
  class PointOfInterest < Base
    attr_accessor :shape_referential

    attribute :name
    attribute :zip_code
    attribute :city_name
    attribute :category
    attribute :shape_provider_id

    def candidate_categories
      shape_referential.point_of_interest_categories
    end

    def candidate_shape_providers
      shape_referential.shape_providers
    end

    def shape_provider
      candidate_shape_providers.find_by(id: shape_provider_id)
    end

    def query(scope)
      Query::PointOfInterest.new(scope).name(name).zip_code(zip_code)
                     .city_name(city_name).category(category).shape_provider(shape_provider)
    end

    class Order < ::Search::Order
      attribute :name, default: :asc
    end
  end
end
