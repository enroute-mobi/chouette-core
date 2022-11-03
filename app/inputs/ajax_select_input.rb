class AjaxSelectInput < SimpleForm::Inputs::CollectionSelectInput
  delegate :content_tag, :concat, :javascript_additional_packs, to: :template

  def input(wrapper_options)
    label_method, value_method = detect_collection_methods

    merged_input_options = merge_wrapper_options(
      input_html_options.merge(),
      {}
    )

    javascript_additional_packs 'inputs/ajax_select'

    @builder.collection_select(
      attribute_name,
      collection,
      :first,
      :second,
      input_options,
      merged_input_options
    ) 

  end

end
