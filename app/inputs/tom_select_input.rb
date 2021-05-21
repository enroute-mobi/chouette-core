class TomSelectInput < SimpleForm::Inputs::CollectionSelectInput
  def input(wrapper_options)
    label_method, value_method = detect_collection_methods

    template.content_tag(:div) do
      template.concat @builder.collection_select(attribute_name, collection, value_method, label_method, input_options, input_html_options)
      # template.concat init_select2
    end
  end

  def input_html_options
    super.merge('x-ref': x_ref)
  end

  def input_id
    "#{object_name}_#{attribute_name}"
  end

  def x_ref
    options[:input_html].fetch(:'x-ref', input_id)
  end

  def x_model
    options[:input_html].fetch(:'x-model')
  end

  def init_select2
    config = tom_select_config

    template.content_tag(
      :script,
      ( 
        %Q(
          window.initTomSelect('##{input_id}', #{tom_select_config})
        )
      ).html_safe
    )
  end

  def tom_select_config
    JSON.generate(options[:select_options] || {}) 
  end
end