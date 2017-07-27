RSpec.describe RetryService do
  subject { described_class.new delays: [2, 3], rescue_from: [NameError, ArgumentError] }

  context 'no retry necessary' do
    before do
      expect( subject ).not_to receive(:sleep)
    end

    it 'returns a tuple :ok and the result' do
      expect( subject.execute { 42 } ).to eq([:ok, 42])
    end
    it 'does not fail on nil' do
      expect( subject.execute { nil } ).to eq([:ok, nil])
    end

    it 'fails wihout retries if raising un unregistered exception' do
      expect{ subject.execute{ raise KeyError } }.to raise_error(KeyError)
    end

  end

  context 'all retries fail' do
    before do
      expect( subject ).to receive(:sleep).with(2)
      expect( subject ).to receive(:sleep).with(3)
    end
    it 'fails after raising a registered exception n times' do
      result = subject.execute{ raise ArgumentError }
      expect( result.first ).to eq(:error)
      expect( result.last ).to be_kind_of(ArgumentError)
    end
    it 'fails with an explicit try again (automatically registered exception)'  do
      result = subject.execute{ raise RetryService::Retry }
      expect( result.first ).to eq(:error)
      expect( result.last ).to be_kind_of(RetryService::Retry)
    end
  end

  context "if at first you don't succeed" do
    before do
      @count = 0
      expect( subject ).to receive(:sleep).with(2)
    end

    it 'succeds the second time' do
      expect( subject.execute{ succeed_later(ArgumentError){ 42 } } ).to eq([:ok, 42])
    end

    it 'succeeds the second time with try again (automatically registered exception)' do
      expect( subject.execute{ succeed_later(RetryService::Retry){ 42 } } ).to eq([:ok, 42])
    end
  end

  context 'last chance' do
    before do
      @count = 0
      expect( subject ).to receive(:sleep).with(2)
      expect( subject ).to receive(:sleep).with(3)
    end
    it 'succeeds the third time with try again (automatically registered exception)' do
      expect( subject.execute{ succeed_later(RetryService::Retry, count: 2){ 42 } } ).to eq([:ok, 42])
    end
  end

  context 'failure callback once' do 
    before do
      @failures = 0
      @count    = 0
      expect( subject ).to receive(:sleep).with(2)
      subject.register_failure_callback { |reason, count| @reason=reason; @callback_count=count; @failures += 1 }
    end
    it 'succeeds the second time and calls the failure_callback once' do
      subject.execute{ succeed_later(RetryService::Retry){ 42 } }
      expect( @failures ).to eq(1)
    end
    it '... and the failure is passed into the callback' do
      subject.execute{ succeed_later(RetryService::Retry){ 42 } }
      expect( @reason ).to be_a(RetryService::Retry)
      expect( @callback_count ).to eq(1)
    end
  end

  context 'failure callback twice' do
    before do
      @failures = 0
      @count    = 0
      expect( subject ).to receive(:sleep).with(2)
      expect( subject ).to receive(:sleep).with(3)
      subject.register_failure_callback { @failures += 1 }
    end
    it 'succeeds the third time and calls the failure_callback twice' do
      subject.execute{ succeed_later(NameError, count: 2){ 42 } }
      expect( @failures ).to eq(2)
    end
  end

  context 'failure callback in constructor' do
    subject do
      described_class.new(delays: [1]){ @failures += 1}
    end
    before do
      @failures = 0
      @count    = 0
      expect( subject ).to receive(:sleep).with(1)
    end
    it 'succeeds the second time and calls the failure_callback once' do
      subject.execute{ succeed_later(RetryService::Retry){ 42 } }
      expect( @failures ).to eq(1)
    end
  end

  def succeed_later error, count: 1, &blk
    return blk.() unless @count < count
    @count += 1
    raise error, 'error'
  end
end
