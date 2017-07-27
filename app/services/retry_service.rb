class RetryService

  Retry = Class.new(RuntimeError)

  def initialize( delays:, rescue_from: [], &blk )
    @intervals             = delays
    @registered_exceptions = Array(rescue_from) << Retry
    @failure_callback      = blk
  end

  def execute &blk
    status, result = execute_protected blk
    return [status, result] if status == :ok
    @intervals.each_with_index do | interval, retry_count |
      @failure_callback.try(:call, result, retry_count.succ)
      sleep interval
      status, result = execute_protected blk
      return [status, result] if status == :ok
    end
    [status, result]
  end

  def register_failure_callback &blk
    @failure_callback = blk
  end


  private

  def execute_protected blk
    [:ok, blk.()]
  rescue Exception => e
    if @registered_exceptions.any?{ |re| e.is_a? re }
      [:error, e]
    else
      raise
    end
  end
end
