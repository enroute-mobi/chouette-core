module PaginationHelper

  def paginated_content(models, default_partial_name = nil, options = {})
    default_options = {:delete => true, :edit => true}
    options = default_options.merge(options)

    # return "" if models.blank?

    html = ""
    models.each_slice(3) do |row_models|
      html += '<div class="row">'
      row_models.each do |model|
        partial_name = default_partial_name || model.class.name.underscore.gsub("chouette/", "")
        html += '<div  class="col-md-4">' + (render :partial => partial_name, :object => model, :locals => options).to_s + '</div>'
      end
      html += '</div>'
    end

    return html.html_safe unless models.blank?
  end

  def new_pagination collection, cls = nil, **options
    # k = collection.first.class unless collection.empty?
    pinfos = page_entries_info collection, html: false
    if collection.total_pages > 1
      links = content_tag :div, '', class: 'page_links' do
        will_paginate collection, container: false, page_links: false, previous_label: '', next_label: '', param_name: (collection.try(:pagination_param_name) || "page"), renderer: options[:renderer]
      end

      content_tag :div, pinfos.concat(links).html_safe, class: "pagination #{cls}"
    else
      content_tag :div, pinfos, class: "pagination #{cls}"
    end
  end

end
