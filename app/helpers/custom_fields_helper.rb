module CustomFieldsHelper
  def custom_fields_for_section(form, section)
    resource = form.object
    return if resource.custom_fields.for_section(section).blank?
    fields = resource.custom_fields.for_section(section).map do |_code, field|
      field.input(form).to_s
    end
    fields.join.html_safe
  end
end
