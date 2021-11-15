# Provide (very simple) cache implementations
#
# Used to avoid ugly hashes with the same behaviors like:
# * limit the entry count
# * manage different values according the I18n locale
#
# The key value is optional.
#
# Examples
#
#    cache = SmartCache::Memory.new
#    cache.fetch { "value" }
#    cache.fetch(:first) { "first value" }
#    cache.fetch(:second) { "second value" }
#
#    cache = SmartCache::Sized.new
#    100000000.times { |n| cache.fetch(n) { "value" } }
#
#    cache = SmartCache::Localized.new
#    I18n.locale = :fr
#    cache.fetch { "valeur" }
#    I18n.locale = :en
#    cache.fetch { "value" }
#
#    cache = SmartCache::Localized.new(store: SmartCache::Sized.new)
#    cache.fetch(record.id) { record.translated_attribute(I18n.locale) }
#
module SmartCache

  class Memory

    def initialize
      @values = {}
    end

    def fetch(key = nil, &block)
      @values[key] ||= block.call
    end

  end

  class Sized

    def initialize(max_size: 250)
      @max_size = max_size
      @values = {}
      @last_entries = []
    end
    attr_reader :max_size

    def fetch(key = nil, &block)
      @values[key] ||=
        begin
          on_new_key key
          block.call
        end
    end

    protected

    def size
      @values.size
    end

    def on_new_key(key)
      @last_entries << key
      clean_entries
    end

    def clean_entries
      @values.delete(@last_entries.shift) while size >= max_size
    end

  end

  class Localized

    def initialize(store: Memory.new, locale_provider: I18n)
      @store = store
      @locale_provider = locale_provider
    end

    attr_reader :store, :locale_provider

    def fetch(key = nil, &block)
      store.fetch [locale_provider.locale, key ], &block
    end

  end

end
