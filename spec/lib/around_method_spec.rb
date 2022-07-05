RSpec.describe AroundMethod do
  class self::Test
    include AroundMethod
    around_method :test

    def around_test
      @around_test_invoked = true
      yield
    end

    def around_test_invoked?
      @around_test_invoked
    end

    def test
      @test_invoked = true
    end

    def test_invoked?
      @test_invoked
    end
  end

  subject(:instance) { self.class::Test.new }

  context "when method is invoked" do
    before { instance.test }

    it "invokes the around method" do
      is_expected.to be_around_test_invoked
    end

    it "the original method is invoked" do
      is_expected.to be_test_invoked
    end
  end
end
