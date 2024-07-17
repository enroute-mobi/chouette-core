module Search
  class Network < Base
    attr_accessor :line_referential

    attribute :name

    def query(scope)
      Query::Document.new(scope).name(name)
    end

    class Order < ::Search::Order
      attribute :name, default: :asc
    end
  end
end
