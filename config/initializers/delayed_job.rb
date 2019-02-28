require 'delayed_job'

class AutoKillPlugin < Delayed::Plugin
  callbacks do |lifecycle|
    lifecycle.after(:perform) do |worker, job|
      if autokill_queues.include? job.queue
        worker.say "Job done, Killing myself"
        worker.stop
      end
    end
  end

  def self.autokill_queues
    %w[imports exports]
  end
end

class Delayed::Heartbeat::Worker
  def fail_jobs
    jobs.each do |job|
      obj = job.payload_object.object
      obj.try(:worker_died)
    end
  end

  def self.handle_dead_workers
    dead_workers(SmartEnv[:DELAYED_JOB_REAPER_HEARTBEAT_TIMEOUT_SECONDS]).each(&:fail_jobs).each &:delete
  end
end

Delayed::Worker.plugins << AutoKillPlugin

# we have some VERY LONG jobs
# we may want to customize this on a per-queue base
Delayed::Worker.max_run_time = 8.hours

Delayed::Worker.logger = Logger.new(File.join(Rails.root, 'log', 'delayed_job.log'))

Delayed::Heartbeat.configure do |configuration|
  configuration.enabled = SmartEnv.boolean :ENABLE_DELAYED_JOB_REAPER
  configuration.heartbeat_interval_seconds = SmartEnv[:DELAYED_JOB_REAPER_HEARTBEAT_INTERVAL_SECONDS]
  configuration.heartbeat_timeout_seconds = SmartEnv[:DELAYED_JOB_REAPER_HEARTBEAT_TIMEOUT_SECONDS]
  configuration.worker_termination_enabled = SmartEnv.boolean :DELAYED_JOB_REAPER_WORKER_TERMINATION_ENABLED
end
