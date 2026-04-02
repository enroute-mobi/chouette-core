class FullTimeZoneInput < SimpleForm::Inputs::CollectionSelectInput

  mattr_reader :collection_cache, default: SmartCache::Localized.new

  delegate :content_tag, :concat, :javascript_additional_packs, to: :template

  def self.default_collection
    collection_cache.fetch do
      raw_collection = {}
      # TODO Optimize TimeZone collection build
      TZInfo::Timezone.all_identifiers.map do |identifier|
        tzinfo = TZInfo::Timezone.get identifier
        tz = ActiveSupport::TimeZone[identifier]
        raw_collection[[tz.utc_offset, tzinfo.friendly_identifier(true)]] =
          ["(#{tz.formatted_offset}) #{tzinfo.friendly_identifier(true)}", tz.name]
      end
      raw_collection.sort.map(&:last).unshift([I18n.t('none'), nil])
    end
  end

  def collection
    @collection ||= begin
      collection = options.delete(:collection) || self.class.default_collection
      collection.respond_to?(:call) ? collection.call : collection.to_a
    end
  end

  def detect_collection_methods
    label, value = options.delete(:label_method), options.delete(:value_method)

    label ||= :first
    value ||= :last
    [label, value]
  end

  def input(wrapper_options)
    label_method, value_method = detect_collection_methods

    plugin_list = input_html_options[:multiple] ? ['clear_button', 'remove_button'] : ['clear_button']

    config = {
      plugins: plugin_list,
      openOnFocus: true,
      sortField: [{field:'$order'},{field:'$score'}]
    }

    # Vérifier s'il y a une option vide
    if collection.any? { |option| option.last.nil? || option.last == "" }
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
      collection,
      value_method,
      label_method,
      input_options,
      merged_input_options
    )
  end
end
