module ProfilingSupport
  extend ActiveSupport::Concern

  included do |into|
    attr_accessor :profiler
    attr_accessor :profile
    attr_accessor :profile_options
    attr_accessor :profile_times
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
      @profile_times.each do |k, times|
        sum = times.sum
        profile_stats[k] = {
          sum: sum,
          count: times.count,
          min: times.min,
          max: times.max,
          average: sum/times.count
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
    out = time = nil
    begin
      time = ::Benchmark.realtime do
        puts "START PROFILING #{@current_profile_scope.join('.')}"  if profile?
        out = yield
      end
      add_profile_time @current_profile_scope.join('.'), time if profile?
    ensure
      puts "END PROFILING #{@current_profile_scope.join('.')} in #{time}s" if profile?
      @current_profile_scope.pop
    end
    out
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
