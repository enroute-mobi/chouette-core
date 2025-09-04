# frozen_string_literal: true

class PublicationSetupDecorator < Af83::Decorator
  prepend ExportSetupDecorator

  decorates PublicationSetup

  set_scope { context[:workgroup] }

  create_action_link

  action_link(on: %i[index], secondary: :index) do |l|
    l.content { I18n.t('publication_setups.actions.show_publications') }
    l.href { h.workgroup_publications_path(scope) }
  end

  with_instance_decorator do |instance_decorator|
    instance_decorator.crud

    instance_decorator.action_link(
      on: %i[show index],
      secondary: :show,
      if: -> { context[:workgroup].output.current && check_policy(:create, Publication) }
    ) do |l|
      l.content { I18n.t('publication_setups.actions.publish') }
      l.method :post
      l.href { h.workgroup_publication_setup_publications_path(scope, object) }
    end

    instance_decorator.action_link(
      on: %i[show],
      secondary: :show
    ) do |l|
      l.content { I18n.t('publication_setups.actions.show_publications') }
      l.href { h.workgroup_publications_path(scope, 'search[publication_setup_id]' => object.id) }
    end

    instance_decorator.class_eval do
      delegate :export_type, to: :object

      alias_method :super_alpine_state, :alpine_state

      def alpine_state
        super_alpine_state.merge(
          {
            isExport: false
          }
        )
      end

      def export_setup_method_name
        :export_setup
      end
    end
  end
end
