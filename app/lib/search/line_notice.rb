module Search
  class LineNotice < Base
    # All search attributes
    attribute :text
    attribute :line_id

    attr_accessor :workbench
    delegate :line_referential, to: :workbench

		validates :line, inclusion: { in: ->(search) { search.candidate_lines } }, allow_blank: true, allow_nil: true

    def query(scope)
			Query::LineNotice.new(scope)
				.text(text)
				.line(line)
    end

		def line
      line_referential.lines.find(line_id) if line_id.present?
    end

    def candidate_lines
      line_referential.lines.order(:name)
    end

		private

    class Order < ::Search::Order
      attribute :title, default: :asc
      attribute :content, default: :asc
    end
  end
end
