require 'delayed_job'

class AutoKillPlugin < Delayed::Plugin
  callbacks do |lifecycle|
    lifecycle.after(:perform) do |worker, job|
      worker.say "Job done, using #{worker.memory_use.to_i}M"
      if worker.memory_used > 1024
        worker.say "Killing myself"
        worker.stop
      end
    end
  end
end

class Delayed::Heartbeat::Worker
  def fail_jobs
    jobs.each do |job|
      obj = job.payload_object.object
      obj.try(:worker_died)
      job.delete
    end
  end

  def self.handle_dead_workers
    dead_workers(SmartEnv[:DELAYED_JOB_REAPER_HEARTBEAT_TIMEOUT_SECONDS]).each(&:fail_jobs).each &:delete
  end
end

class Delayed::Worker
  def memory_used
    NewRelic::Agent::Samplers::MemorySampler.new.sampler.get_sample
  end
end

class Delayed::Job
  def initialize_with_organisation(options)
    initialize_without_organisation options
    payload_object = options[:payload_object]
    object = payload_object&.object
    if object&.respond_to?(:organisation)
      self.organisation_id = object.organisation&.id
    end
    if object&.respond_to?(:operation_type)
      self.operation_type = object.operation_type
    end
  end
  alias_method_chain :initialize, :organisation

  def self.locked
    where.not(locked_at: nil)
  end

  def self.for_organisation(organisation)
    organisation_id = organisation.try(:id) || organisation
    self.where(organisation_id: organisation_id)
  end
end

class Delayed::Backend::ActiveRecord::Job
  class << self
    def reserve(worker, max_run_time = Delayed::Worker.max_run_time)
      ready_scope = ready_to_run(worker.name, max_run_time).min_priority.max_priority.for_queues.by_priority
      offset = 0
      next_in_line = ready_scope.first

      return reserve_with_scope(ready_scope, worker, db_time_now) unless next_in_line

      top_priority = next_in_line.priority
      ready_scope = ready_scope.where(priority: top_priority)

      while next_in_line && job_organisation_already_processing?(next_in_line)
        offset += 1
        next_in_line = ready_scope.offset(offset).first
      end
      ready_scope = ready_scope.where(id: next_in_line.id) if next_in_line

      reserve_with_scope(ready_scope, worker, db_time_now)
    end

    def job_organisation_already_processing?(job)
      Delayed::Job.locked.for_organisation(job.organisation_id).exists?
    end
  end
end

Delayed::Worker.plugins << AutoKillPlugin

Delayed::Worker.queue_attributes = {
  imports: { max_run_time: 10.hours },
  exports: { max_run_time: 4.hours }
}

Delayed::Worker.logger = Logger.new(File.join(Rails.root, 'log', 'delayed_job.log'))

Delayed::Heartbeat.configure do |configuration|
  configuration.enabled = SmartEnv.boolean :ENABLE_DELAYED_JOB_REAPER
  configuration.heartbeat_interval_seconds = SmartEnv[:DELAYED_JOB_REAPER_HEARTBEAT_INTERVAL_SECONDS]
  configuration.heartbeat_timeout_seconds = SmartEnv[:DELAYED_JOB_REAPER_HEARTBEAT_TIMEOUT_SECONDS]
  configuration.worker_termination_enabled = SmartEnv.boolean :DELAYED_JOB_REAPER_WORKER_TERMINATION_ENABLED
end
