module Search
  class LineGroup < Base
    extend Enumerize

    # All search attributes
    attribute :text
    attribute :lines
    attribute :line_provider

    attr_accessor :workbench

    delegate :line_referential, to: :workbench

    def query(scope)
      Query::LineGroup.new(scope)
                     .text(text)
                     .lines(lines)
                     .line_provider_id(line_provider)
    end

    def candidate_lines
      workbench.line_referential.lines.where(id: lines)
    end

    def candidate_line_providers
      line_referential.line_providers
    end

    private

    class Order < ::Search::Order
      attribute :name, default: :desc
    end
  end
end
