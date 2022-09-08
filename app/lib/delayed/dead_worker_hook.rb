# frozen_string_literal: true

module Delayed
  # Invokes a :dead_worker hook on jobs associated to workers ckeaned by Delayed::Heartbeat
  #
  # Use to override Delayed::Heartbeat
  module DeadWorkerHook
    def self.cleanup_workers(workers, mark_attempt_failed: true)
      workers.each do |worker|
        worker.jobs.each do |job|
          Rails.logger.info "Invoke dead_worker hook on job #{job.name}"
          job.hook(:dead_worker)
        end
      end

      super
    end
  end
end
