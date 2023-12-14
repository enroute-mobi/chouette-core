class TimestampsInserter
  def initialize(_target, now_provider: Time.zone)
    @now_provider = now_provider
  end

  attr_reader :now_provider

  def now
    @now ||= now_provider.now
  end

  TIMESTAMPS = %i[created_at= updated_at=]
  def each_timestamp(&block)
    TIMESTAMPS.each(&block)
  end

  def insert(model, options = {})
    each_timestamp do |timestamp_setter|
      model.send timestamp_setter, now if model.respond_to?(timestamp_setter)
    end
  end
end
