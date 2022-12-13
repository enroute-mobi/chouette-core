class SourceDecorator < AF83::Decorator
  decorates Source

  set_scope { context[:workbench] }

  create_action_link

  with_instance_decorator do |instance_decorator|
    instance_decorator.crud

    instance_decorator.action_link(on: %i[show], policy: :retrieve, secondary: :show) do |l|
      l.content t('sources.actions.retrieve')
      l.href { h.retrieve_workbench_source_path(scope, object) }
      l.method :post
    end
  end

  define_instance_method :displayed_url do
    uri = URI(url)
    uri.user = 'xxx' if uri.user
    uri.password = 'xxx' if uri.password
    uri.to_s
  end
end
