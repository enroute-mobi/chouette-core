class ExportDecorator < AF83::Decorator
  decorates Export::Base

  set_scope { context[:parent] }

  define_instance_method :export_status_css_class do
    cls = ''
    cls = 'overheaded-success' if object.status == 'successful'
    cls = 'overheaded-warning' if object.status == 'warning'
    cls = 'overheaded-danger' if %w[failed aborted canceled].include? object.status
    cls
  end

  define_instance_method :exported_lines_types_options do
    [
      ['Specific Lines', 'line'],
      ['Company Set', 'company'],
      ['Line Provider Set', 'line_provider'],
    ]
  end

  define_instance_method :line_options do
    object.workbench.lines
  end

  define_instance_method :companies_options do
    object.workbench.companies.map { |c| [c.name, c.line_ids] }
  end

  define_instance_method :line_providers_options do
    object.workbench.line_providers.map { |lp| [lp.short_name, lp.line_ids] }
  end

  create_action_link if: -> { context[:parent].is_a?(Workbench) }

  with_instance_decorator do |instance_decorator|
    instance_decorator.show_action_link

    instance_decorator.action_link primary: :show do |l|
      l.content t('actions.download')
      l.icon :download
      l.href   { [:download, scope, object] }
      l.disabled { !object.file.present? }
      l.download { [:download, scope, object] }
      l.target :blank
    end
  end
end
