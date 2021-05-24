class TomSelectInput < SimpleForm::Inputs::CollectionSelectInput
  def input(wrapper_options)
    label_method, value_method = detect_collection_methods

    template.content_tag(:div) do
      template.concat @builder.collection_select(attribute_name, collection, value_method, label_method, input_options, input_html_options)
    end
  end
end