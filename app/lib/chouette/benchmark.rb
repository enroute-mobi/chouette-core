module Chouette
  module Benchmark

    def self.measure(name, attributes = {}, &block)
      full_name(name) do |full_name|
        attributes[:full_name] = full_name
        create(name, attributes, &block).measure
      end
    end
    # Deprecated
    def self.log(name, &block)
      measure name, &block
    end

    def self.benchmark_classes
      @benchmark_classes ||= [Log, Datadog, Memory, Realtime].select(&:enabled?)
    end

    def self.create(name, attributes = {}, &block)
      benchmark = Call.new(block)
      attributes = attributes.merge(name: name)

      benchmark_classes.reverse_each do |benchmark_class|
        benchmark = benchmark_class.new benchmark, attributes
      end

      benchmark
    end

    thread_mattr_accessor :current_name

    def self.full_name(name)
      previous_name = self.current_name

      full_name = previous_name ? "#{previous_name}.#{name}" : name
      begin
        self.current_name = full_name
        yield full_name
      ensure
        self.current_name = previous_name
      end
    end

    class Call

      def initialize(proc)
        @proc = proc
      end

      def measure
        @proc.call
      end

    end

    class Base

      def self.enabled?
        true
      end

      attr_reader :attributes, :next_benchmark

      def initialize(next_benchmark, attributes = {})
        @next_benchmark, @attributes = next_benchmark, attributes
      end

      def name
        attributes[:name]
      end

      def full_name
        attributes[:full_name]
      end

      mattr_reader :ignored_attributes, default: [:name, :full_name]
      def user_attributes
        @user_attributes ||= attributes.reject { |k,_| ignored_attributes.include?(k) }
      end

      def measure
        next!
      end

      def next!
        next_benchmark.measure
      end

      def results
        if next_benchmark.respond_to?(:results)
          next_benchmark.results
        else
          {}
        end
      end

    end

    class Realtime < Base

      attr_accessor :time

      def measure
        result = nil
        self.time = ::Benchmark.realtime do
          result = next!
        end
        result
      end

      def results
        return super if time < 1
        super.merge(time: time.to_i)
      end

    end

    class Memory < Base

      attr_accessor :delta, :before, :after

      def measure
        self.before = current_usage
        result = next!
        self.after = current_usage
        self.delta = after - before
        result
      end

      def results
        return super if delta < 10
        super.merge(memory_delta: delta.to_i, memory_after: after.to_i)
      end

      def current_usage
        Chouette::Benchmark.current_usage
      end

    end

    class Log < Base

      def measure
        result = next!
        unless results.empty?
          Rails.logger.info "[Benchmark] #{full_name}#{attributes_part}: #{results_part}"
        end
        result
      end


      def attributes_part
        return "" if user_attributes.empty?

        pretty_attributes = user_attributes.map { |k,v| "#{k}:#{v}" }.join(', ')
        "(#{pretty_attributes})"
      end

      def results_part
        return "" if results.empty?
        results.map { |k,v| "#{k}=#{v}" }.join(', ')
      end

    end

    # Use Datadog tracing API to create span according to benchmark measures
    class Datadog < Base
      def self.enabled?
        @enabled ||= ENV.key?('DD_AGENT_HOST')
      end

      def measure
        ::Datadog::Tracing.trace(full_name, datadog_options) do |_span|
          next!
        end
      end

      def datadog_options
        { tags: user_attributes }
      end
    end

    KERNEL_PAGE_SIZE = `getconf PAGESIZE`.chomp.to_i rescue 4096
    STATM_PATH       = "/proc/#{Process.pid}/statm"
    STATM_FOUND      = File.exist?(STATM_PATH)

    def self.current_usage
      STATM_FOUND ? (File.read(STATM_PATH).split(' ')[1].to_i * KERNEL_PAGE_SIZE) / 1024 / 1024.0 : 0
    end

  end
end
