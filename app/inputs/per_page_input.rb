class PerPageInput < SimpleForm::Inputs::StringInput
  delegate :content_tag, :concat, :link_to, :javascript_additional_packs, to: :template

  def input(wrapper_options)
    javascript_additional_packs 'inputs/per_page'

    content_tag(:div, class: 'flex items-center') do
      concat link_to "30", '', class: "btn-link mx-2", style: "#{value == 30 ? 'font-weight: bold' : ''}", 'data-per_page': 30, 'x-on:click': 'onPerPageClick'
      concat "-"
      concat link_to "50", '', class: "btn-link mx-2", style: "#{value == 50 ? 'font-weight: bold' : ''}", 'data-per_page': 50, 'x-on:click': 'onPerPageClick'
      concat "-"
      concat link_to "100", '', class: "btn-link ml-2", style: "#{value == 100 ? 'font-weight: bold' : ''}", 'data-per_page': 100, 'x-on:click': 'onPerPageClick'
      concat @builder.hidden_field(attribute_name)
     end
  end

  def value
    object.send(attribute_name) if object.respond_to? attribute_name
  end
end
