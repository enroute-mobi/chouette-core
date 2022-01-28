class TomSelectInput < SimpleForm::Inputs::CollectionInput
  def input(wrapper_options)
    label_method, value_method = detect_collection_methods

    merged_input_options = merge_wrapper_options(input_html_options, wrapper_options)

    config = options.fetch(:config, {})

    select = @builder.collection_select(
        attribute_name,
        collection,
        Proc.new { |i| i[:id] },
        Proc.new { |i| i[:text] },
        input_options,
        merged_input_options.merge(
          class: 'tom_selectable',
          'data-config': config.to_json
        )
      )

    id = input_class

    template.content_tag(:div) do
      template.concat select

      template.concat template.javascript_tag(
        %{
          var waitFor = name => {
            setTimeout(() => {
              window.hasOwnProperty(name) ? window[name]('#{id}') : waitFor(name)
            }, 100)
          }
          waitFor('initTomSelect')
        },
        defer: true
      )
    end
  end
  
end
