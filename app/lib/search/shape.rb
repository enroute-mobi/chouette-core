# frozen_string_literal: true

module Search
  class Shape < Base
    attribute :text

    attr_accessor :workbench

    def searched_class
      ::Shape
    end

    def query(scope)
      Query::Shape.new(scope) \
                  .text(text)
    end

    class Order < ::Search::Order
      attribute :name, default: :asc
    end
  end
end
