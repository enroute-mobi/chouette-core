class PublicationSetupDecorator < AF83::Decorator
  decorates PublicationSetup

  set_scope { context[:workgroup] }

  with_instance_decorator do |instance_decorator|
    instance_decorator.crud

    instance_decorator.action_link(on: %i[show index], secondary: :show) do |l|
      l.content I18n.t('publication_setups.actions.publish')
      l.method :post
      l.href { h.workgroup_publication_setup_publications_path(scope, object) }
    end
  end
end
