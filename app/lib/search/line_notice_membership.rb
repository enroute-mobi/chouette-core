module Search
  class LineNoticeMembership < Base
    # All search attributes
    attribute :text

    attr_accessor :workbench
    delegate :line_referential, to: :workbench

    def query(scope)
			Query::LineNoticeMembership.new(scope)
				.text(text)
    end

		private

    class Order < ::Search::Order
      attribute :title, joins: :line_notice, column: 'line_notices.title', default: :asc
      attribute :content, joins: :line_notice, column: 'line_notices.content', default: :asc
    end
  end
end
