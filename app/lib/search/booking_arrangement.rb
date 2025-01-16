# frozen_string_literal: true

module Search
  class BookingArrangement < Base
    extend Enumerize

    # All search attributes
    attribute :text

    attr_accessor :workbench

    delegate :line_referential, to: :workbench

    def query(scope)
      Query::LineGroup.new(scope)
                      .text(text)
    end

    class Order < ::Search::Order
      attribute :name, default: :desc
    end
  end
end
