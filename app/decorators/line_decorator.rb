class LineDecorator < AF83::Decorator
  decorates Chouette::Line

  set_scope { [ context[:workbench], :line_referential ] }

  create_action_link do |l|
    l.content t('lines.actions.new')
  end

  with_instance_decorator do |instance_decorator|
    instance_decorator.crud

    instance_decorator.action_link secondary: :show do |l|
      l.content t('lines.actions.show_network')
      l.href   { [scope, object.network] }
      l.disabled { object.network.nil? }
    end

    instance_decorator.action_link secondary: :show do |l|
      l.content  t('lines.actions.show_company')
      l.href     { [scope, object.company] }
      l.disabled { object.company.nil? }
    end

    instance_decorator.action_link secondary: :show do |l|
      l.content  { Chouette::LineNotice.t.capitalize }
      l.href     { [scope, object, :line_notices] }
    end
  end

  define_instance_method :documents_table do
    documents = DocumentDecorator.decorate(object.documents, context: context.merge(parent: object))

    h.table_builder_2(
      documents,
      [
        TableBuilderHelper::Column.new(key: :uuid, attribute: :uuid, sortable: false),
        TableBuilderHelper::Column.new(key: :name, attribute: :name, sortable: false), 
        TableBuilderHelper::Column.new( \
          key: :document_type_id,
          attribute: -> (doc) { doc.document_type.short_name },
          sortable: false,
          link_to: -> (doc) { h.workgroup_document_type_path(context[:workbench].workgroup, doc.document_type) }
        )
      ],
      sortable: false,
      cls: 'table'
    )
  end
end
