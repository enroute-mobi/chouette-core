# frozen_string_literal: true

module Delayed
  module ReadyToRunWithoutLockedAt
    def self.prepended(base)
      base.singleton_class.prepend(ClassMethods)
    end

    module ClassMethods
      def ready_to_run(worker_name, _max_run_time)
        where(
          '((run_at <= ? AND locked_at IS NULL) OR locked_by = ?) AND failed_at IS NULL',
          db_time_now,
          worker_name
        )
      end
    end
  end
end
