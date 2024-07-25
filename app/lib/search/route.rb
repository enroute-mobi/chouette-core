module Search
  class Route < Base
    # All search attributes
    attribute :text
    attribute :wayback

    attr_accessor :workbench

    def query(scope)
      Query::Route.new(scope)
                    .text(text)
                    .wayback(wayback)
    end

    private

    class Order < ::Search::Order
      attribute :name, default: :asc
      attribute :wayback
    end
  end
end
