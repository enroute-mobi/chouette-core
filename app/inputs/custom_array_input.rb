class CustomArrayInput < SimpleForm::Inputs::Base

  def input(wrapper_options = {})
    merged_input_options = merge_wrapper_options(input_html_options, wrapper_options)
    @builder.text_field(attribute_name, merged_input_options)
  end

  def input_html_options
    super.merge({'data-role': 'tagsinput', type: 'text'})
  end
end
