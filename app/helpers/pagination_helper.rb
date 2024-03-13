module PaginationHelper

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
