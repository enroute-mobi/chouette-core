# frozen_string_literal: true

require 'delayed_job_active_record'

# Add organisation management for Job
class Delayed::Job # rubocop:disable Style/ClassAndModuleChildren(RuboCop)
  prepend Delayed::WithOrganisation
  prepend Delayed::UniqReservation
end

# Add :dead_worker hook
module Delayed::Heartbeat # rubocop:disable Style/ClassAndModuleChildren(RuboCop)
  prepend Delayed::DeadWorkerHook
end

# Restart worker when too much memory is used
Delayed::Worker.plugins << Delayed::AutoKillPlugin

# Enable metrics report
Delayed::Worker.plugins << Delayed::Metrics

Delayed::Worker.max_run_time = SmartEnv[:DELAYED_JOB_MAX_RUN_TIME].hours

Delayed::Heartbeat.configure do |configuration|
  configuration.enabled = SmartEnv.boolean :ENABLE_DELAYED_JOB_REAPER
  configuration.heartbeat_interval_seconds = SmartEnv[:DELAYED_JOB_REAPER_HEARTBEAT_INTERVAL_SECONDS]
  configuration.heartbeat_timeout_seconds = SmartEnv[:DELAYED_JOB_REAPER_HEARTBEAT_TIMEOUT_SECONDS]
  configuration.worker_termination_enabled = SmartEnv.boolean :DELAYED_JOB_REAPER_WORKER_TERMINATION_ENABLED
end

if Rails.env.development?
  # Disable default auto reloading
  # See https://github.com/collectiveidea/delayed_job/pull/1115
  Delayed::Worker.instance_exec do
    def self.reload_app?
      false
    end
  end

  # Reload code before each job
  # Delayed::Worker.plugins << Delayed::ReloaderPlugin
end
