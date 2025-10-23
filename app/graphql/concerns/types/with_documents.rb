# frozen_string_literal: true

module Types
  module WithDocuments
    extend ActiveSupport::Concern

    included do
      field :documents, [Types::DocumentType], null: true
    end

    def documents
      LazyLoading::Documents.new(context, object)
    end
  end
end
