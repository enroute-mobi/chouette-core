module Search
  class Company < Base
    # All search attributes
    attribute :text
    attribute :is_referent

    attr_accessor :line_referential

    def query(scope)
      Query::Company.new(scope)
                    .text(text)
                    .is_referent(is_referent)
    end

    def is_referent
      flag(super)
    end

    private

    def flag(value)
      ActiveModel::Type::Boolean.new.cast(value)
    end

    class Order < ::Search::Order
      attribute :name, default: :asc
    end
  end
end
