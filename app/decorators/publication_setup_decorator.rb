# frozen_string_literal: true

class PublicationSetupDecorator < AF83::Decorator
  decorates PublicationSetup

  set_scope { context[:workgroup] }

  with_instance_decorator do |instance_decorator|
    instance_decorator.crud

    instance_decorator.action_link(
      on: %i[show index],
      secondary: :show,
      if: -> { context[:workgroup].output.current && check_policy(:create, Publication) }
    ) do |l|
      l.content I18n.t('publication_setups.actions.publish')
      l.method :post
      l.href { h.workgroup_publication_setup_publications_path(scope, object) }
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
