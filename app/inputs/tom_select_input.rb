class TomSelectInput < SimpleForm::Inputs::CollectionSelectInput
  def input(wrapper_options)
    label_method, value_method = detect_collection_methods

    config = options.fetch(:config, {})

    select = @builder.collection_select(
        attribute_name,
        collection,
        Proc.new { |i| i[:id] },
        Proc.new { |i| i[:text] },
        input_options.merge(
          include_hidden: false
        ),
        input_html_options.merge(
          class: 'tom_selectable',
          'data-config': config.to_json
        )
      )

    id = select.scan(/id="([^"]*)"/).first.first.to_s # TODO Find a better way to find the auto generated input id

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
