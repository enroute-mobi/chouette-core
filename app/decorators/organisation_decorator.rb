# frozen_string_literal: true

class OrganisationDecorator < AF83::Decorator
  decorates Organisation

  with_instance_decorator do |instance_decorator|
    instance_decorator.action_link primary: :show, policy: :edit do |l|
      l.content Organisation.t_action(:edit)
      l.href { h.edit_organisation_path }
      l.icon :'pencil-alt'
    end
  end
end
