module LinksHelper
  def destroy_link_content(translation_key = 'actions.destroy')
    content_tag(:span, nil, class: 'fa fa-trash mr-xs') + t(translation_key)
  end
end
