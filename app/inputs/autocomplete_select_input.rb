class AutocompleteSelectInput < SimpleForm::Inputs::CollectionSelectInput

  def collection
    []
  end

  def input(wrapper_options = {})
    _options = wrapper_options.dup.update({
      data: {
        'select2-ajax': true,
        url: options[:autocomplete_url],
        "load-url": options[:load_url],
        values: [object.send(reflection_or_attribute_name)].flatten,
        placeholder: options[:placeholder] || ""
      }
    })

    super _options
  end
end
