class AutocompleteSelectInput < SimpleForm::Inputs::CollectionSelectInput
  delegate :content_tag, :concat, :javascript_additional_packs, to: :template

  def input(wrapper_options)
    label_method, value_method = detect_collection_methods
    # reset wrapper_options with {} (remove double div around the input)
    merged_input_options = merge_wrapper_options(input_html_options, {})

    javascript_additional_packs 'inputs/autocomplete_select'

    @builder.collection_select(
      attribute_name, collection, value_method, label_method,
      input_options, merged_input_options
    )
  end
end
