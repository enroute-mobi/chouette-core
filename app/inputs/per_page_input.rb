class PerPageInput < SimpleForm::Inputs::StringInput
  delegate :content_tag, :concat, :link_to, :javascript_additional_packs, to: :template

  # Fake input with several links + hidden input
  # We use AlpineJS to dynamically set hidden input value + submit form when user click on link
  def input(wrapper_options)
    content_tag(:div, class: 'flex items-center', 'x-data': "{ #{attribute_name}: #{value} }", 'x-init': "$watch('#{attribute_name}', () => document.querySelector('form').submit())") do
      concat link_to "30", '', class: "btn-link mx-2", style: "#{value == 30 ? 'font-weight: bold' : ''}", 'x-on:click.prevent': "#{attribute_name} = 30"
      concat "-"
      concat link_to "50", '', class: "btn-link mx-2", style: "#{value == 50 ? 'font-weight: bold' : ''}", 'x-on:click.prevent': "#{attribute_name} = 50"
      concat "-"
      concat link_to "100", '', class: "btn-link ml-2", style: "#{value == 100 ? 'font-weight: bold' : ''}", 'x-on:click.prevent': "#{attribute_name} = 100" 
      concat @builder.hidden_field(attribute_name, { 'x-model': attribute_name })
     end
  end

  def value
    object.send(attribute_name) if object.respond_to? attribute_name
  end
end
