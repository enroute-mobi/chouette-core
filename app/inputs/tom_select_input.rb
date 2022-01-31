class TomSelectInput < SimpleForm::Inputs::CollectionSelectInput
  delegate :content_tag, :concat, :javascript_additional_packs, to: :template

  def input(wrapper_options)
    label_method, value_method = detect_collection_methods

    config = options.fetch(:config, {})

    merged_input_options = merge_wrapper_options(
      input_html_options.merge(
        'x-data': '',
        'x-init': "initTomSelect($el, #{config.to_json})"
      ),
      {}
    )

    javascript_additional_packs 'inputs/tom_select'

    @builder.collection_select(
      attribute_name,
      collection,
      Proc.new { |i| i[:id] },
      Proc.new { |i| i[:text] },
      input_options,
      merged_input_options
    )
  end
  
end
