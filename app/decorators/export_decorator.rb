# frozen_string_literal: true

class ExportDecorator < Af83::Decorator
  prepend ExportSetupDecorator

  decorates Export::Base

  set_scope { context[:parent] }

  define_instance_method :export_status_css_class do
    cls = ''
    cls = 'overheaded-success' if object.status == 'successful'
    cls = 'overheaded-warning' if object.status == 'warning'
    cls = 'overheaded-danger' if %w[failed aborted canceled].include? object.status
    cls
  end

  create_action_link if: -> { context[:parent].is_a?(Workbench) }

  with_instance_decorator do |instance_decorator|
    instance_decorator.show_action_link

    instance_decorator.action_link primary: :show do |l|
      l.content { I18n.t('actions.download') }
      l.icon :download
      l.href   { [:download, scope, object] }
      l.disabled { !object.file.present? }
      l.download { [:download, scope, object] }
      l.target :blank
    end

    instance_decorator.class_eval do
      def alpine_state
        base_alpine_state.merge(
          {
            isExport: true,
            referentialId: object.referential_id
          }
        )
      end

      def export_type
        object.type
      end

      def export_setup_method_name
        :setup
      end
    end
  end

  define_instance_method :display_selected_lines_to_export do
    object.workgroup.line_referential.lines.where(
      id: Export::Scope::Options.new(referential, setup, id).line_ids
    ).limit(15).pluck(:name).join(', ')
  end

  define_instance_method :display_code_space do
    object.code_space&.to_label
  end
end
