# frozen_string_literal: true
class DocumentDecorator < AF83::Decorator
  decorates Document

  set_scope { context[:workbench] }

  create_action_link


  define_instance_method :display_validity_period_part do |part|
    value = validity_period.try(part)

    return '-' if value.nil?
    return '-' if value.is_a?(Float)

    I18n.l(value)
  end

  define_instance_method :json_state do
    JSON.generate({
                    filename: file&.file&.filename || '',
                    errors: errors.messages.slice(:file, :validity_period).values
                  })
  end

  define_instance_method :preview_json do
    JSON.generate({
                    contentType: file.content_type,
                    url: file.url
                  })
  end

  with_instance_decorator do |instance_decorator|
    instance_decorator.action_link secondary: :show do |l|
      l.content t('documents.actions.download')
      l.icon :download
      l.href { [:download, scope, object] }
      l.disabled { !object.file.present? }
      l.download { [:download, scope, object] }
      l.target :blank
    end
  end

  with_instance_decorator(&:crud)
end
