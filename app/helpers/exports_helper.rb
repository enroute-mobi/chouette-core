module ExportsHelper
  def export_message_content(message)
    if message.message_key == 'full_text'
      message.message_attributes['text']
    else
      message_key = [message.class.name.underscore.gsub('/', '_').pluralize, message.message_key].join('.')

      message_attributes = message.message_attributes&.symbolize_keys || {}
      message_attributes.transform_values! do |value|
        sanitize(value)
      end

      # Because .. one import message includes an URL ...
      t(message_key, message_attributes).html_safe
    end
  end

  def workgroup_exports(workgroup)
    workgroup.export_types.map(&:constantize)
  end
end
