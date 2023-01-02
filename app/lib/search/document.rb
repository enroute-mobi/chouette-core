module Search
  class Document < Base
    attr_accessor :workgroup

    attribute :name
    attribute :document_type
    attribute :valid_after_date, type: Date
    attribute :valid_before_date, type: Date

    def candidate_document_types
      workgroup.document_types
    end

    def period
      Period.new(from: valid_after_date, to: valid_before_date).presence
    end

    def query
      Query::Document.new(scope).name(name).document_type(document_type)
      # Query::Document.new(scope).name(name).document_type(document_type).in_period(period)
    end

    class Order < ::Search::Order
      attribute :name, default: :desc
    end
  end
end
