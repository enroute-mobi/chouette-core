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
        each_element_in_document_memberships do |document_membership, document_name|
          document_membership.save

          messages.create(source: document_membership.documentable, document_name: document_name) do |message|
            message.error! unless document_membership.valid?
          end
        end
      end

      def each_element_in_document_memberships(&block)
        PostgreSQLCursor::Cursor.new(query).each do |attributes|
          document_name = attributes.delete 'document_name'
          document_membership = DocumentMembership.new attributes

          block.call document_membership, document_name
        end
      end

      def query
        models
          .joins(model_codes)
          .joins(document_codes)
          .joins(documents)
          .joins(outer_join_document_memberships)
          .where(document_memberships: { id: nil })
          .select(select)
          .to_sql
      end

      def select
        <<-SQL
          document_codes.resource_id AS document_id,
          documents.name AS document_name,
          #{model_collection}.id AS documentable_id,
          model_codes.resource_type AS documentable_type
        SQL
      end

      def documents
        <<-SQL
          INNER JOIN public.documents ON public.documents.id = document_codes.resource_id
        SQL
      end

      def model_codes
        <<-SQL
          INNER JOIN public.codes model_codes
          ON model_codes.resource_type = #{documentable_type}
          AND model_codes.resource_id = #{model_collection}.id
          AND model_codes.code_space_id = #{model_code_space}
        SQL
      end

      def document_codes
        <<-SQL
          INNER JOIN public.codes document_codes
          ON document_codes.resource_type = 'Document'
          AND document_codes.code_space_id = #{document_code_space}
          AND document_codes.value = model_codes.value
        SQL
      end

      def outer_join_document_memberships
        <<-SQL
          LEFT OUTER JOIN public.document_memberships
          ON documentable_type = #{documentable_type}
          AND documentable_id = #{model_collection}.id
          AND document_id = document_codes.resource_id
        SQL
      end

      def documentable_type
        @documentable_type ||= "'Chouette::#{target_model}'"
      end

      def models
        @models ||= scope.send(model_collection)
      end

      def model_collection
        @model_collection ||= target_model.underscore.pluralize
      end

      protected

      def messages_options
        {
          resource_name_key: :model_name
        }
      end
    end
  end
end
