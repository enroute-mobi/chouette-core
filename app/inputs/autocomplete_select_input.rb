class AutocompleteSelectInput < SimpleForm::Inputs::CollectionSelectInput

  def collection
    []
  end

  def input(wrapper_options = {})
    _options = wrapper_options.dup.update({
      "class": [wrapper_options["class"], "autocomplete-async-input"].compact.join(' '),
      data: {
        url: options[:autocomplete_url],
        "load-url": options[:load_url],
        values: [object.send(reflection_or_attribute_name)].flatten,
        placeholder: options[:placeholder] || ""
      }
    })

    super _options
  end
end
