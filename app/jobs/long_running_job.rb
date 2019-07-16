LongRunningJob = Struct.new(:object, :method, :args) do
  def max_attempts
    1
  end

  def perform
    object.send method, *args
  end

  def max_run_time
    Delayed::Worker.max_run_time
  end

  def explain
    "#{object.class}(id=#{object.id}).#{method}(#{[args].flatten.map(&:inspect).join(', ')})"
  end
end
