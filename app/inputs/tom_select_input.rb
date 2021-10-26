class TomSelectInput < SimpleForm::Inputs::CollectionSelectInput
  def input(wrapper_options)
    label_method, value_method = detect_collection_methods

    config = options.fetch(:config, {})

    select = @builder.collection_select(
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

    id = select.scan(/id="([^"]*)"/).first.first.to_s # TODO Find a better way to find the auto generated input id

    template.content_tag(:div) do
      template.concat select

      template.concat template.javascript_tag "initTomSelect('#{id}')"
    end
  end
end
