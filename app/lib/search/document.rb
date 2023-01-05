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
      Period.new(from: valid_before_date , to: valid_after_date ).presence
    end

    validates :period, valid: true

    def query
      Query::Document.new(scope).name(name).document_type(document_type).in_period(period)
    end

    class Order < ::Search::Order
      attribute :name, default: :desc
    end
  end
end
