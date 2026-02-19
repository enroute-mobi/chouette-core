# frozen_string_literal: true
class ImportDecorator < Af83::Decorator
  decorates Import::Base

  set_scope { context[:parent] }

  define_instance_method :first_child do
    return @first_child if defined?(@first_child)

    @first_child ||= object.children.first
  end

  define_instance_method :import_status_css_class do
    cls =''
    cls = 'overheaded-success' if object.status == 'successful'
    cls = 'overheaded-warning' if object.status == 'warning'
    cls = 'overheaded-danger' if %w[failed aborted canceled].include? object.status
    cls
  end

  define_instance_method :permitted_options do
    object.visible_options.select { |k, _v| h.policy(object).option?(k) }
  end

  define_instance_method :duration do
    child = object.children.first

    if child&.ended_at&.present? && child&.started_at&.present?
      child.ended_at - child.started_at
    elsif ended_at.present? && started_at.present?
      ended_at - started_at
    else
      nil
    end
  end

  create_action_link if: -> { context[:parent].is_a? (Workbench) }

  with_instance_decorator do |instance_decorator|
    instance_decorator.show_action_link

    instance_decorator.action_link primary: :show do |l|
      l.content { I18n.t('imports.actions.download') }
      l.icon :download
      l.href   { [:download, scope, object] }
      l.disabled { !object.file.present? }
      l.download { [:download, scope, object] }
      l.target :blank
    end

    instance_decorator.action_link secondary: :show do |l|
      l.content { I18n.t('imports.show.all_messages') }
      l.href { h.workbench_import_messages_path(scope, object.children.first) }
      l.disabled { object.children.blank? }
    end
  end
end
