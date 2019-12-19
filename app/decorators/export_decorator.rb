class ExportDecorator < AF83::Decorator
  decorates Export::Base

  set_scope { context[:workbench] }

  define_instance_method :export_status_css_class do
    cls =''
    cls = 'overheaded-success' if object.status == 'successful'
    cls = 'overheaded-warning' if object.status == 'warning'
    cls = 'overheaded-danger' if %w[failed aborted canceled].include? object.status
    cls
  end

  create_action_link

  with_instance_decorator do |instance_decorator|
    instance_decorator.show_action_link

    instance_decorator.action_link primary: :show do |l|
      l.content t('actions.download')
      l.icon :download
      l.href   { h.download_workbench_export_path object.workbench, object }
      l.disabled { !object.file.present? }
      l.download { h.download_workbench_export_path object.workbench, object }
      l.target :blank
    end

  end
end
