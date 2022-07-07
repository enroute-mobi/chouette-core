class PerPageInput < SimpleForm::Inputs::StringInput
  delegate :content_tag, :concat, :link_to, to: :template

  def input(wrapper_options)
    content_tag(:div, class: 'flex items-center') do
       concat link_to "30", '?per_page=30', class: 'btn-link mr-2'
       concat link_to "50", '?per_page=50', class: 'btn-link mr-2'
       concat link_to "100", '?per_page=100', class: 'btn-link'
     end
  end
end