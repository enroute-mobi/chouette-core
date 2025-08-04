# frozen_string_literal: true

module Search
  class Calendar < Base
    # All search attributes
    attribute :text
    attribute :shared, type: Boolean
    attribute :contains_date, type: Date

    attr_accessor :workbench

    def searched_class
      ::Calendar
    end

    def query(scope)
      Query::Calendar.new(scope) \
                     .text(text) \
                     .shared(shared) \
                     .contains_date(contains_date)
    end

    class Order < ::Search::Order
      attribute :name, default: :asc
      attribute :organisation, joins: :organisation, column: 'organisations.name'
      attribute :shared
    end
  end
end
