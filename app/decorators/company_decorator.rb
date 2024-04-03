# frozen_string_literal: true

class CompanyDecorator < AF83::Decorator
  include DocumentableDecorator

  decorates Chouette::Company

  set_scope { [ context[:workbench], :line_referential ] }

  create_action_link do |l|
    l.content { h.t('companies.actions.new') }
  end

  with_instance_decorator do |instance_decorator|
    instance_decorator.crud
  end

  def policy_parent
    context[:workbench].default_line_provider
  end
end
