class LineDecorator < AF83::Decorator
  decorates Chouette::Line

  set_scope { context[:line_referential] }

  create_action_link do |l|
    l.content t('lines.actions.new')
  end

  with_instance_decorator do |instance_decorator|
    ### primary (and secondary) can be
    ### - a single action
    ### - an array of actions
    ### - a boolean

    instance_decorator.show_action_link

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

    can_edit_line = ->(){ h.policy(Chouette::Line).create? && context[:line_referential].organisations.include?(context[:current_organisation]) }

    instance_decorator.with_condition can_edit_line do
      edit_action_link do |l|
        l.content {|l| l.primary? ? h.t('actions.edit') : h.t('lines.actions.edit') }
      end
    end

    instance_decorator.destroy_action_link
  end
end
