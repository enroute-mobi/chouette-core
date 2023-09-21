# frozen_string_literal: true

module Query
  class PointOfInterest < Base
    def name(value)
      where(value, :matches, :name)
    end

    def zip_code(value)
      where(value, :matches, :zip_code)
    end

    def city_name(value)
      where(value, :matches, :city_name)
    end

    def category(category)
      change_scope(if: category.present?) do |scope|
        scope.with_category(category)
      end
    end

    def shape_provider(value)
      change_scope(if: value.present?) do |scope|
        scope.where(shape_provider: value)
      end
    end
  end
end
