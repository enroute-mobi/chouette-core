# frozen_string_literal: true

module Search
  class Document < Base
    attr_accessor :workgroup

    attribute :name
    attribute :document_type
    attribute :document_provider_id
    attribute :valid_after_date, type: Date
    attribute :valid_before_date, type: Date

    period :period, :valid_before_date, :valid_after_date

    def searched_class
      ::Document
    end

    def candidate_document_types
      workgroup.document_types
    end

    def candidate_document_providers
      workgroup.document_providers
    end

    def document_provider
      candidate_document_providers.find_by(id: document_provider_id)
    end

    def query(scope)
      Query::Document.new(scope).name(name).document_type(document_type)
                     .document_provider(document_provider).in_period(period)
    end

    class Order < ::Search::Order
      attribute :name, default: :asc
    end
  end
end
