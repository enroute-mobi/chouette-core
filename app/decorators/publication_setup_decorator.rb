# frozen_string_literal: true

class PublicationSetupDecorator < Af83::Decorator
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
  end

  define_instance_method :display_profile_options do
    displayed_profile_options = ""
    object.profile_options.each_pair do |key, value|
      displayed_profile_options += ", " if displayed_profile_options.present?
      displayed_profile_options += "#{key} : #{value}"
    end
    displayed_profile_options
  end
end
