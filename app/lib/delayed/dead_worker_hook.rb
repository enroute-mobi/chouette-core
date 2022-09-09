# frozen_string_literal: true

module Delayed
  # Invokes a :dead_worker hook on jobs associated to workers ckeaned by Delayed::Heartbeat
  #
  # Use to override Delayed::Heartbeat
  module DeadWorkerHook
    def self.prepended(base)
      class << base
        prepend ClassMethods
      end
    end

    module ClassMethods # rubocop:disable Style/Documentation
      def cleanup_workers(workers, mark_attempt_failed: true)
        Rails.logger.debug "Cleanup workers with dead_worker hook support #{workers.map(&:name).join(',')}"

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
end
