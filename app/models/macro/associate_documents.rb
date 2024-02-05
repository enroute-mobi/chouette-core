# frozen_string_literal: true

module Macro
  class AssociateDocuments < Macro::Base
    module Options
      extend ActiveSupport::Concern

      included do
        option :target_model
        option :model_code_space
        option :document_code_space

        enumerize :target_model, in: %w[StopArea Line]
        validates :target_model, :model_code_space, :document_code_space, presence: true
      end
    end

    include Options

    class Run < Macro::Base::Run
      include Options

      def run
        each_element_in_document_memberships do |document_membership, document_name, model_name|
          document_membership.save
          create_message(document_membership, document_name, model_name)
        end
      end

      def create_message(document_membership, document_name, model_name)
        attributes = {
          message_attributes: {
            document_name: document_name,
            model_name: model_name
          },
          source: document_membership.documentable
        }

        attributes.merge!(criticity: 'error', message_key: 'error') unless document_membership.valid?

        macro_messages.create!(attributes)
      end

      def each_element_in_document_memberships(&block)
        PostgreSQLCursor::Cursor.new(query).each do |attributes|
          document_name = attributes.delete 'document_name'
          model_name = attributes.delete 'model_name'
          document_membership = DocumentMembership.new attributes

          block.call document_membership, document_name, model_name
        end
      end

      def documentable_type
        @documentable_type ||= "'Chouette::#{target_model}'"
      end

      def query
        <<~SQL
          SELECT
            documents_models_by_codes.document_id AS document_id,
            documents_models_by_codes.document_name AS document_name,
            documents_models_by_codes.model_name AS model_name,
            documents_models_by_codes.model_id AS documentable_id,
            #{documentable_type} AS documentable_type
          FROM (#{documents_models_by_codes}) AS documents_models_by_codes
          LEFT JOIN (#{customized_document_memberships}) AS customized_document_memberships
          ON documents_models_by_codes.document_model_id = customized_document_memberships.document_model_id
          WHERE customized_document_memberships.document_model_id IS NULL
        SQL
      end

      def customized_document_memberships
        document_memberships.select('*', "CONCAT(document_id, '-', documentable_id) AS document_model_id").to_sql
      end

      def documents_models_by_codes
        <<~SQL
          SELECT
            documents_with_codes.document_id AS document_id,
            documents_with_codes.document_name AS document_name,
            models_with_codes.model_id AS model_id,
            models_with_codes.model_name AS model_name,
            CONCAT(documents_with_codes.document_id, '-', models_with_codes.model_id) AS document_model_id
          FROM  (#{documents_with_codes}) AS documents_with_codes
          INNER JOIN (#{models_with_codes}) AS models_with_codes
          ON documents_with_codes.document_code_value = models_with_codes.model_code_value
        SQL
      end

      def documents_with_codes
        documents
          .select(
            'documents.id AS document_id',
            'documents.name AS document_name',
            'codes.value AS document_code_value')
          .joins(codes: :code_space)
          .where('code_spaces.id' => document_code_space)
          .to_sql
      end

      def models_with_codes
        models
          .select(
            "#{model_collection}.id AS model_id",
            "#{model_collection}.name AS model_name",
            'codes.value AS model_code_value')
          .joins(codes: :code_space)
          .where('code_spaces.id' => model_code_space)
          .to_sql
      end

      def models
        @models ||= scope.send(model_collection)
      end

      def model_collection
        @model_collection ||= target_model.underscore.pluralize
      end

      def document_memberships
        @document_memberships ||= workbench.document_memberships
      end

      def documents
        @documents ||= workbench.documents
      end
    end
  end
end
