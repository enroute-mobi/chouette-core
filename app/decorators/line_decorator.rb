# frozen_string_literal: true

class LineDecorator < AF83::Decorator
  include DocumentableDecorator

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

  define_instance_method :human_status do
    h.t(status, scope: 'activerecord.attributes.line')
  end

  def policy_parent
    context[:workbench].default_line_provider
  end
end
