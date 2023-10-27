class EditableSelectInput < SimpleForm::Inputs::StringInput
  delegate :javascript_additional_packs, to: :template

  def input(wrapper_options = nil)
    unless string?
      input_html_classes.unshift("string")
      input_html_options[:type] ||= input_type if html5?
    end

    javascript_additional_packs 'inputs/editable_select'

    merged_input_options = merge_wrapper_options(input_html_options, wrapper_options)

    @builder.text_field(attribute_name, merged_input_options)
  end

  def input_html_classes
    super.push('w-full')
  end
end
