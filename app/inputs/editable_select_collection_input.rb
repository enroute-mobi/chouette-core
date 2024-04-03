class EditableSelectCollectionInput < SimpleForm::Inputs::CollectionSelectInput
  delegate :javascript_additional_packs, to: :template

  def input(wrapper_options = nil)
    label_method, value_method = detect_collection_methods

    javascript_additional_packs 'inputs/editable_select_collection'

    merged_input_options = merge_wrapper_options(input_html_options, {})

    @builder.collection_select(
      attribute_name, collection, value_method, label_method,
      input_options, merged_input_options
    )
  end

  def input_html_classes
    super.push('w-full')
  end
end
