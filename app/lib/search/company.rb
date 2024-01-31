module Search
  class Company < Base
    # All search attributes
    attribute :text

    attr_accessor :line_referential

    def query(scope)
      Query::Company.new(scope)
                    .text(text)
    end

    class Order < ::Search::Order
      attribute :name, default: :asc
    end
  end
end
