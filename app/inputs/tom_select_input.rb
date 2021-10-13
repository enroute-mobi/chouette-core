class TomSelectInput < SimpleForm::Inputs::CollectionSelectInput
  def input(wrapper_options)
    label_method, value_method = detect_collection_methods

    config = options.fetch(:config, {})

    template.content_tag(:div) do
      template.concat @builder.collection_select(
        attribute_name,
        collection,
        Proc.new { |i| i[:id] },
        Proc.new { |i| i[:text] },
        input_options,
        input_html_options.merge(
          class: 'tom_selectable',
          'data-config': config.to_json
        )
      )

      template.concat template.javascript_pack_tag 'inputs/tom_select'
    end
  end
end