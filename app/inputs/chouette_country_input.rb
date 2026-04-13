class ChouetteCountryInput < SimpleForm::Inputs::CollectionSelectInput
  delegate :content_tag, :concat, :javascript_additional_packs, to: :template

  def input(wrapper_options)
    label_method, value_method = detect_collection_methods

    plugin_list = input_html_options[:multiple] ? ['clear_button', 'remove_button'] : ['clear_button']

    config = {
      plugins: plugin_list,
      openOnFocus: true,
      sortField: [{field:'$order'},{field:'$score'}]
    }

    collection_to_use = options.delete(:collection) || country_options

    if collection_to_use.any? { |option| option.last.nil? || option.last == "" }
      config[:allowEmptyOption] = true
    end

    x_init = input_html_options.delete(:"x-init") || ''

    merged_input_options = merge_wrapper_options(
      input_html_options.merge(
        'x-data': '{ tomSelect: null }',
        'x-init': "tomSelect = initTomSelect($el, #{config.to_json}); #{x_init}"
      ),
      {}
    )

    javascript_additional_packs 'inputs/tom_select'

    @builder.collection_select(
      attribute_name,
      collection_to_use,
      value_method,
      label_method,
      input_options,
      merged_input_options
    )
  end

  private

  def country_options
    priority_countries = options.delete(:priority) || []
    
    prioritized = priority_countries.map do |code|
      country = ISO3166::Country.find_country_by_alpha2(code)
      country ? [country.translations[I18n.locale.to_s] || country.common_name, code] : nil
    end.compact
    
    all_countries = ISO3166::Country.all.map do |country|
      [country.translations[I18n.locale.to_s] || country.common_name, country.alpha2]
    end
    
    priority_codes = prioritized.map(&:last)
    other_countries = all_countries.reject { |_, code| priority_codes.include?(code) }
    
    result = options[:include_blank] ? [[I18n.t('simple_form.include_blank'), '']] : []
    result + prioritized + other_countries
  end

  def detect_collection_methods
    label, value = options.delete(:label_method), options.delete(:value_method)

    label ||= :first
    value ||= :last
    [label, value]
  end
end
