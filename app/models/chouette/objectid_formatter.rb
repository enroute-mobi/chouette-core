module Chouette
  module ObjectidFormatter
    def self.reset_objectid_providers_cache!
      @_cache = nil
    end

    def self.for_objectid_provider(provider_class, provider_scope)
      @_cache ||= SmartCache::Sized.new
      cache_key = { provider_class.name => provider_scope }
      @_cache.fetch cache_key do
        provider = provider_class.find_by provider_scope
        provider.objectid_formatter
      end
    end
  end
end
