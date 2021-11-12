class FullTimeZoneInput < SimpleForm::Inputs::CollectionSelectInput

  mattr_reader :collection_cache, default: SmartCache::Localized.new

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

  def input_html_options
    options = super
    options[:data] = (options[:data] || {}).merge(select2ed: true)
    options
  end

  def input(wrapper_options = {})
    super wrapper_options
  end
end
