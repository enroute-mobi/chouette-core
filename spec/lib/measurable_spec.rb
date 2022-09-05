RSpec.describe Measurable do
  # Test class
  class self::Test # rubocop:disable Lint/ConstantDefinitionInBlock
    include Measurable

    def test
      @test_invoked = true
    end

    def test_invoked?
      @test_invoked
    end
  end

  subject(:test_class) { self.class::Test }
  subject(:instance) { test_class.new }

  context 'when the method is measure without option' do
    before { test_class.measure :test }

    it 'invokes the initial method' do
      expect { instance.test }.to change(instance, :test_invoked?).to(true)
    end

    it 'starts a benchmark measure' do
      expect(Chouette::Benchmark).to receive(:measure).with('test')
      instance.test
    end
  end

  context 'when the method is measure with an as value' do
    before { test_class.measure :test, as: :alias }

    it 'invokes the initial method' do
      expect { instance.test }.to change(instance, :test_invoked?).to(true)
    end

    it 'starts a benchmark measure with "alias" name' do
      expect(Chouette::Benchmark).to receive(:measure).with('alias')
      instance.test
    end
  end

  context 'when the method is measure with an as Proc' do
    before do
      allow(instance).to receive(:alias_name).and_return('dummy')
      test_class.measure :test, as: ->(instance) { instance.alias_name }
    end

    it 'invokes the initial method' do
      expect { instance.test }.to change(instance, :test_invoked?).to(true)
    end

    it 'starts a benchmark measure with the result of Proc' do
      expect(Chouette::Benchmark).to receive(:measure).with('dummy')
      instance.test
    end
  end
end
