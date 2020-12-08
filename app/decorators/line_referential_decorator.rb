class LineReferentialDecorator < AF83::Decorator
  decorates LineReferential

  set_scope { [context[:workbench]] }

  with_instance_decorator do |instance_decorator|

    instance_decorator.action_link policy: :synchronize, primary: :show do |l|
      l.content t('actions.sync')
      l.href { h.sync_workbench_line_referential_path(context[:workbench]) }
      l.method :post
    end

  end
end
