# frozen_string_literal: true

module Delayed
  # Used to customize Delayed::Backend::ActiveRecord::Job
  module WithConcurrentTarget
    extend ActiveSupport::Concern

    prepended do
      before_create :store_concurrent_target

      # Limit for locked/running jobs for each concurrent target
      mattr_accessor :max_workers_per_concurrent_target, default: 1

      scope :in_concurrent_target_bounds, lambda {
        # unscope to ensure it can be used as subquery
        ignored_concurrent_targets = all.unscope(:where, :order).out_of_bounds_concurrent_targets
        if ignored_concurrent_targets.present?
          where('concurrent_target not in (?) or concurrent_target is null', ignored_concurrent_targets)
        else
          all
        end
      }
      scope :locked, -> { where.not(locked_at: nil) }
      scope :with_concurrent_target, -> { where.not(concurrent_target: nil) }

      # Warining: ready_to_run is Delayed::Job existing method
      scope :ready, -> { legacy_ready_to_run.in_concurrent_target_bounds }
      scope :legacy_ready_to_run, -> { where 'run_at <= now() AND locked_at IS NULL AND failed_at IS NULL' }
    end

    class_methods do
      # Overrides Delayed::Backend::ActiveRecord::Job#reserve_with_scope to ignore pending jobs
      # whose concurrent target has reached the job limit
      #
      # See https://github.com/collectiveidea/delayed_job_active_record/blob/master/lib/delayed/backend/active_record.rb
      def reserve_with_scope(ready_scope, worker, now)
        super ready_scope.in_concurrent_target_bounds, worker, now
      end

      # Returns concurrent_targets associated to more locked jobs than max_workers_per_concurrent_target
      def out_of_bounds_concurrent_targets
        locked.with_concurrent_target.group(:concurrent_target)
              .having('count(id) >= ?', max_workers_per_concurrent_target).pluck(:concurrent_target)
      end

      def pending_count
        locked.count + ready.count
      end
    end

    private

    # Store the concurrent target identifier provided by the job
    def store_concurrent_target
      self.concurrent_target ||= payload_object.try(:concurrent_target)
    end
  end
end
