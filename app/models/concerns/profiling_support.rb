module ProfilingSupport
  extend ActiveSupport::Concern

  included do |into|
    attr_accessor :profiler
    attr_accessor :profile
    attr_writer   :profile_options
    attr_accessor :profile_times
  end

  def profile_options
    @profile_options ||= {}
  end

  def add_profile_time(tag, time)
    @profile_times ||= Hash.new{ |h, k| h[k] = [] }
    @profile_times[tag] << time
  end

  def profile?
    @profile
  end

  def profile_stats
    @profile_times ||= Hash.new{ |h, k| h[k] = [] }
    @computed_profile_stats ||= begin
      profile_stats = {}
      @profile_times.each do |k, data|
        times = data.map{|k| k[:time]}
        mems = data.map{|k| k[:mem]}
        sum = times.sum
        mem_sum = mems.sum
        profile_stats[k] = {
          count: data.count,
          total_time: sum,
          min_time: times.min,
          max_time: times.max,
          average_time: sum/data.count,
          total_mem: mem_sum,
          min_mem: mems.min,
          max_mem: mems.max,
          average_mem: mem_sum/data.count
        }
      end
      profile_stats
    end
  end

  def profile_tag(tag, &block)
    if profiler
      profiler.profile_tag tag, &block
      return
    end

    @current_profile_scope ||= []
    @current_profile_scope << tag
    out = time = mem = nil
    begin
      memory_before = Chouette::Benchmark.current_usage
      time = ::Benchmark.realtime do
        log "START PROFILING #{@current_profile_scope.join('.')}" if profile?
        out = yield
      end
      memory_after = Chouette::Benchmark.current_usage
      mem = memory_after - memory_before
      add_profile_time @current_profile_scope.join('.'), { time: time, mem: mem } if profile?
    ensure
      log "END PROFILING #{@current_profile_scope.join('.')} in #{time}s - mem delta: #{mem}" if profile?
      @current_profile_scope.pop
    end
    out
  end

  def log msg
    msg = msg.try(:white) || msg
    puts msg
  end

  def profile_operation(operation, &block)
    if profile?
      profile_tag operation, &block
    else
      Chouette::Benchmark.log "#{self.class.name} run #{operation}" do
        yield
      end
    end
  end
end
