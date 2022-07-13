class PerPageInput < SimpleForm::Inputs::StringInput
  delegate :content_tag, :concat, :link_to, :request, to: :template

  def input(_wrapper_options)
    content_tag(:div, class: 'flex items-center') do
      concat per_page_link(30)
      concat separator
      concat per_page_link(50)
      concat separator
      concat per_page_link(100)
      concat @builder.hidden_field(attribute_name) # Only used when we submit the search form
    end
  end

  def value
    object.send(attribute_name) if object.respond_to? attribute_name
  end

  private

  def per_page_link per_page_value
    link_to(
      per_page_value,
      request.params.merge(per_page: per_page_value),
      class: "btn-link",
      style: "#{value == per_page_value ? 'font-weight: bold' : ''}"
    )
  end

  def separator
    content_tag :span, "-", class: 'mx-1'
  end
end
