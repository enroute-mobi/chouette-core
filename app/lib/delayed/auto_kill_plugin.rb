# frozen_string_literal: true

module Delayed
  # Inspect memory after each job and stop the worker if needed
  class AutoKillPlugin < Plugin
    MAX_MEMORY = 1024
    MAX_MAPS = 1024

    callbacks do |lifecycle|
      lifecycle.after(:perform) do |worker, _|
        memory_used = Chouette::Benchmark.current_usage
        memory_map_used = Chouette::Benchmark.current_map_usage
        worker.say "Job done, using #{memory_used.to_i}M, #{memory_map_used} maps"

        if memory_used > MAX_MEMORY || memory_map_used > MAX_MAPS
          worker.say 'Killing myself'
          worker.stop
        end
      rescue StandardError => e
        Chouette::Safe.capture 'AutoKillPlugin failed', e
      end
    end
  end
end
