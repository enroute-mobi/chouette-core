class TomSelectInput < SimpleForm::Inputs::CollectionSelectInput
  delegate :content_tag, :concat, :javascript_additional_packs, to: :template

  def input(wrapper_options)
    label_method, value_method = detect_collection_methods

    javascript_additional_packs 'inputs/tom_select'
    @builder.collection_select(
      attribute_name,
      collection,
      Proc.new { |i| i[:id] },
      Proc.new { |i| i[:text] },
      input_options.merge(include_hidden: false),
      input_html_options.merge(
        class: 'tom_selectable',
        'data-config': options.fetch(:config, {}).to_json,
        'x-data': '',
        'x-init': "initTomSelect($el)"
      )
    )
  end
end
