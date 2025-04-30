# frozen_string_literal: true

module Delayed
  # Inspect memory after each job and stop the worker if needed
  class AutoKillPlugin < Plugin
    mattr_accessor :maximum_idle_workers, default: 0

    callbacks do |lifecycle|
      lifecycle.after(:perform) do |worker, _|
        status = Status.new
        worker.say "Job done, using #{status.description}"

        if status.must_stop?
          worker.say 'Killing myself'
          worker.stop
        end
      rescue StandardError => e
        Chouette::Safe.capture 'AutoKillPlugin failed', e
      end
    end

    class Status
      def must_stop?
        memory_exceeded? || memory_maps_exceeded? || worker_idle?
      end

      def description
        [
          "#{memory_used}M",
          "#{memory_maps_used} maps",
          "#{worker_count} workers / #{worker_count_expected} expected"
        ].join(', ')
      end

      def memory_exceeded?
        memory_used > memory_limit
      end

      def memory_maps_exceeded?
        memory_maps_used > memory_maps_limit
      end

      def worker_idle?
        worker_count > worker_count_expected
      end

      def memory_used
        Chouette::Benchmark.current_usage.to_i
      end

      MAX_MEMORY = 1024
      def memory_limit
        MAX_MEMORY
      end

      def memory_maps_used
        Chouette::Benchmark.current_map_usage
      end

      MAX_MAPS = 1024
      def memory_maps_limit
        MAX_MAPS
      end

      def worker_count
        Delayed::Heartbeat::Worker.count
      end

      def worker_count_expected
        [pending_jobs, maximum_idle_workers].max
      end

      def pending_jobs
        Delayed::Job.pending_count
      end

      def maximum_idle_workers
        value = Delayed::AutoKillPlugin.maximum_idle_workers.to_i
        return Float::INFINITY if value.zero?

        value
      end
    end
  end
end
