LongRunningJob = Struct.new(:object, :method, :args) do
  attr_accessor :max_attempts

  def max_attempts
    @max_attempts || 1
  end

  def perform
    object.send method, *args
  end

  def max_run_time
    Delayed::Worker.max_run_time
  end

  def explain
    "#{object.class}(id=#{object.try(:id)}).#{method}(#{[args].flatten.map(&:inspect).join(', ')})"
  end
end
