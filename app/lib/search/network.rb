module Search
  class Network < Base
    attr_accessor :line_referential

    attribute :text

    def query(scope)
      Query::Network.new(scope).text(text)
    end

    class Order < ::Search::Order
      attribute :name, default: :asc
    end
  end
end
