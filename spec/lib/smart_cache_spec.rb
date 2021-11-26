RSpec.describe SmartCache::Memory do
  subject(:cache) { SmartCache::Memory.new }

  describe "#fetch" do

    it "returns the cached value" do
      cached_value = double("cached value")
      expect(cache.fetch(:dummy) { cached_value }).to eq(cached_value)
    end

    context "when the value is not in cache" do
      it { expect { |block| cache.fetch(:dummy, &block) }.to yield_with_no_args  }
    end

    context "when the value is in cache" do
      before { cache.fetch(:dummy) { "value" } }
      it { expect { |block| cache.fetch(:dummy, &block) }.to_not yield_with_no_args  }
    end

  end
end

RSpec.describe SmartCache::Sized do
  subject(:cache) { SmartCache::Sized.new }

  describe "#fetch" do

    it "returns the cached value" do
      cached_value = double("cached value")
      expect(cache.fetch(:dummy) { cached_value }).to eq(cached_value)
    end

    context "when the value is not in cache" do
      it { expect { |block| cache.fetch(:dummy, &block) }.to yield_with_no_args  }
    end

    context "when the value is in cache" do
      before { cache.fetch(:dummy) { "value" } }
      it { expect { |block| cache.fetch(:dummy, &block) }.to_not yield_with_no_args  }
    end

    context "when the value count exceed the cache size" do
      before do
        cached_value = double("cached value")
        cache.fetch(:dummy) { cached_value }

        cache.max_size.times do |n|
          cache.fetch("key #{n}") { "value #{n}" }
        end
      end

      it { expect { |block| cache.fetch(:dummy, &block) }.to yield_with_no_args  }
    end

  end
end

RSpec.describe SmartCache::Sized do

  let(:locale_provider) { Struct.new(:locale).new }
  subject(:cache) { SmartCache::Localized.new locale_provider: locale_provider }

  describe "#fetch" do

    it "returns a different value according to the current locale" do
      %i{first second}.each do |locale|
        locale_provider.locale = locale
        localized_value = "value for #{locale}"
        expect(cache.fetch(:dummy) { localized_value }).to eq(localized_value)
      end
    end

  end
end
