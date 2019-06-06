class ImportDecorator < AF83::Decorator
  decorates Import::Base

  set_scope { context[:workbench] || object.workbench }

  define_instance_method :import_status_css_class do
    cls =''
    cls = 'overheaded-success' if object.status == 'successful'
    cls = 'overheaded-warning' if object.status == 'warning'
    cls = 'overheaded-danger' if %w[failed aborted canceled].include? object.status
    cls
  end

  create_action_link if: -> { context[:workbench].present? }

  with_instance_decorator do |instance_decorator|
    instance_decorator.show_action_link

    instance_decorator.action_link secondary: :show do |l|
      l.content t('imports.actions.download')
      l.icon :download
      l.href { object.file.url }
    end
  end
end
