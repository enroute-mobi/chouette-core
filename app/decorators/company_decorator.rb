class CompanyDecorator < AF83::Decorator
  decorates Chouette::Company

  set_scope { [ context[:workbench], :line_referential ] }

  create_action_link do |l|
    l.content { h.t('companies.actions.new') }
  end

  with_instance_decorator do |instance_decorator|
    instance_decorator.show_action_link

    instance_decorator.edit_action_link do |l|
      l.content {|l| l.action == "show" ? h.t('actions.edit') : h.t('companies.actions.edit') }
    end

    instance_decorator.destroy_action_link
  end
end
