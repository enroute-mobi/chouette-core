class PerPageInput < SimpleForm::Inputs::StringInput
  delegate :content_tag, :concat, :link_to, to: :template

  def input(wrapper_options)
    content_tag(:div, class: 'flex items-center') do
       concat link_to "30", '?per_page=30', class: "btn-link mx-2", style: "#{value == 30 ? 'font-weight: bold' : ''}"
       concat "-"
       concat link_to "50", '?per_page=50', class: "btn-link mx-2", style: "#{value == 50 ? 'font-weight: bold' : ''}"
       concat "-"
       concat link_to "100", '?per_page=100', class: "btn-link ml-2", style: "#{value == 100 ? 'font-weight: bold' : ''}"
     end
  end

  def value
    object.send(attribute_name) if object.respond_to? attribute_name
  end
end
