module SimpleSearchForHelper
  def simple_search_for(search, index_path, &block)
    if search.saved_id
      save_path = workbench_stop_areas_search_path(search.workbench, search)
      save_method = :patch
    else
      save_path = workbench_stop_areas_searches_path(search.workbench)
      save_method = :post
    end

    html = {
      class: 'flex items-center tailwind-filters bg-grey relative pr-6', 
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

  end
end
