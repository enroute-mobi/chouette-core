# frozen_string_literal: true

module Types
  class DocumentType < Types::BaseObject
    include Types::WithCodes

    description 'A Document'

    field :uuid, String, null: false
    field :name, String, null: false
    field :description, String, null: true

    field :created_at, GraphQL::Types::ISO8601DateTime, null: true
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: true

    field :validity_period, Period, null: true

    field :document_type, String, null: false
    def document_type
      LazyLoading::DocumentType.new(context, object.id)
    end
  end
end
