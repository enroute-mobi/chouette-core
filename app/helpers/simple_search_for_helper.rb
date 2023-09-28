module SimpleSearchForHelper
  def simple_search_for(search, url, &block)
    if @search.saved_id
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
      url: url, 
      method: "GET", 
      html: html, 
      wrapper: :filters_form_tailwind,
      builder: FormBuilder
    }

    Rails.logger.debug "SimpleSearchForHelper #{options.inspect}"

    simple_form_for(search, options) do |form|
      form.simple_fields_for :order, search.order, defaults: { wrapper: false } do |form_order|
        form_order.object.attributes.keys.each do |attribute|
          concat form_order.input attribute, as: :hidden
        end
      end

      block.call form
    end
  end

  class FormBuilder < SimpleForm::FormBuilder



  end
end