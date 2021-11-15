module SmartCache

  class Memory

    def initialize
      @values = {}
    end

    def fetch(key = nil, &block)
      @values[key] ||= block.call
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
