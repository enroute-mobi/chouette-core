require 'delayed_job'

class AutoKillPlugin < Delayed::Plugin
  callbacks do |lifecycle|
    lifecycle.before(:perform) do |worker, job|
      begin
        explained = job.payload_object.try(:explain) || job.payload_object.inspect
        worker.say "Starting Job #{explained} with priority #{job.priority}, attempt #{job.attempts + 1}/#{job.max_attempts}"
      rescue => e
        Rails.logger.error "Error before starting job: #{e}"
      end
    end

    lifecycle.after(:perform) do |worker, _|
      begin
        worker.say "Job done, using #{worker.memory_used.to_i}M"
        if worker.memory_used > 1024
          worker.say "Killing myself"
          worker.stop
        end
      rescue => e
        Rails.logger.error "Error after job: #{e}"
      end
    end
  end
end

class Delayed::Heartbeat::Worker
  def fail_jobs
    Rails.logger.info "#{inspect}: dealing with failed jobs"
    jobs.each do |job|
      obj = job.payload_object.object
      obj.try(:worker_died)
      job.delete
    end
  end

  def self.handle_dead_workers
    dead_workers(SmartEnv[:DELAYED_JOB_REAPER_HEARTBEAT_TIMEOUT_SECONDS]).each(&:fail_jobs).each(&:delete)
  end
end


module Delayed::VerboseWorker
  def start *args
    say "Queues: #{queues.presence&.to_sentence || 'all'}"
    super
  end
end

class Delayed::Worker
  prepend Delayed::VerboseWorker

  def memory_used
    NewRelic::Agent::Samplers::MemorySampler.new.sampler.get_sample
  end
end

module Delayed::InitializeWithOrganisation
  def initialize(options)
    super options
    payload_object = options[:payload_object]
    object = payload_object.try(:object)
    if object&.respond_to?(:organisation)
      self.organisation_id = object.organisation&.id
    end
    if object&.respond_to?(:operation_type)
      self.operation_type = object.operation_type
    end
  end
end

class Delayed::Job
  prepend Delayed::InitializeWithOrganisation

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
      ready_scope = ready_to_run(worker.name, max_run_time).for_queues(worker.queues).by_priority
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

Delayed::Worker.max_run_time = 10.hours

Delayed::Heartbeat.configure do |configuration|
  configuration.enabled = SmartEnv.boolean :ENABLE_DELAYED_JOB_REAPER
  configuration.heartbeat_interval_seconds = SmartEnv[:DELAYED_JOB_REAPER_HEARTBEAT_INTERVAL_SECONDS]
  configuration.heartbeat_timeout_seconds = SmartEnv[:DELAYED_JOB_REAPER_HEARTBEAT_TIMEOUT_SECONDS]
  configuration.worker_termination_enabled = SmartEnv.boolean :DELAYED_JOB_REAPER_WORKER_TERMINATION_ENABLED
end
