module SimpleSearchForHelper
  def simple_search_for(search, index_path, &block)
    if search.saved_search
      save_path = saved_search_path(search.saved_search)
      save_method = :patch
    else
      save_path = "#{index_path}/searches"
      save_method = :post
    end

    html = {
      class: 'flex items-stretch tailwind-filters bg-grey relative pr-6',
      "x-data": "{ save_path: '#{save_path}', save_method: '#{save_method}'}"
    }
    options = {
      url: index_path,
      method: "GET",
      html: html,
      wrapper: :filters_form_tailwind,
      builder: FormBuilder
    }

    locals = {
      index_path: index_path,
      search: search,
      options: options,
    }

    render layout: 'searches/form', locals: locals, &block
  end

  class FormBuilder < SimpleForm::FormBuilder

    def text
      input :text, label: false, width: 2
    end

    def input attribute, **options
      width = options.delete(:width) || 1
      options[:wrapper_html] ||= { class: "w-#{width}/5 border-l" }

      super attribute, **options
    end

    def row(&block)
      template.content_tag(:div, class: 'flex items-center border-t border-white') do
        yield
      end
    end

  end
end