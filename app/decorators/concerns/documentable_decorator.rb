# frozen_string_literal: true

module DocumentableDecorator
  extend ActiveSupport::Concern

  included do
    define_instance_method :documents_table do
      h.table_builder_2(
        object.documents,
        [
          TableBuilderHelper::Column.new(key: :uuid, attribute: :uuid, sortable: false),
          TableBuilderHelper::Column.new(
            key: :name,
            attribute: :name,
            sortable: false,
            link_to: ->(doc) { h.workbench_document_path(context[:workbench], doc) }
          ),
          TableBuilderHelper::Column.new( \
            key: :document_type_id,
            attribute: ->(doc) { doc.document_type.short_name },
            sortable: false,
            link_to: ->(doc) { h.workgroup_document_type_path(context[:workbench].workgroup, doc.document_type) }
          )
        ],
        sortable: false,
        cls: 'table'
      )
    end
  end
end
