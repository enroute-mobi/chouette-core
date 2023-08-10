# frozen_string_literal: true

module Delayed
  # Measure Delayed Job metrics:
  # * before/after a job is performed
  # * when a job is enqueued
  class Metrics < Plugin
    callbacks do |lifecycle|
      lifecycle.before(:perform) do
        measure
      end

      lifecycle.after(:perform) do
        measure
      end

      lifecycle.after(:enqueue) do
        measure
      end
    end

    def self.measure
      # TODO: could include a cool down to limit measure rate
      Measure.new.measure
    end

    # Performs a Measure: create all Metrics and publish them with all Publishers
    class Measure
      def measure
        publish
      end

      def metric_generators
        [Metric::Count, Metric::Waiting, Metric::Ready, Metric::Locked, Metric::Planned, Metric::Latencies]
      end

      def metrics
        @metrics ||= metric_generators.flat_map(&:create)
      end

      def publisher_classes
        [Publisher::Log, Publisher::Datadog]
      end

      def publishers
        publisher_classes.map(&:new)
      end

      def publish
        publishers.each do |publisher|
          publisher.publish metrics
        end
      end
    end

    module Metric
      # a Basic Metric which given name, value and (optional) tags
      class Base
        def initialize(name = nil, value = nil, tags = {})
          @name = name
          @value = value
          @tags = tags
        end

        attr_reader :name, :value

        def self.create
          new
        end

        def to_s
          "#{name}#{tags_as_string}=#{value}"
        end

        def tags
          @tags ||= {}
        end

        def tags_as_string
          return '' if tags.blank?

          "[#{tags.inspect}]"
        end
      end

      # Measure (global) Delayed::Job count
      class Count < Base
        def value
          Delayed::Job.count
        end

        def name
          'jobs.count'
        end
      end

      # Measure jobs which should have be ran (can be unready)
      class Waiting < Base
        def value
          Delayed::Job.where('run_at < now()').count
        end

        def name
          'jobs.waiting_count'
        end
      end

      # Measure jobs ready to be performed by a Worker (including organisation limit)
      class Ready < Base
        def value
          ready_to_run.in_organisation_bounds.count
        end

        def ready_to_run
          Delayed::Job.where 'run_at <= now() AND locked_at IS NULL AND failed_at IS NULL'
        end

        def name
          'jobs.ready_count'
        end
      end

      # Measure jobs to be ran in the future (like cron jobs)
      class Planned < Base
        def value
          Delayed::Job.where('run_at > now()').count
        end

        def name
          'jobs.planned_count'
        end
      end

      # Measure jobs locked by a worker
      class Locked < Base
        def value
          Delayed::Job.where.not(locked_at: nil).count
        end

        def name
          'jobs.locked_count'
        end
      end

      # Create a latency Metric for each organisation (and none) with the maximum job age
      class Latencies
        def self.create
          new.metrics
        end

        def metrics
          latencies_per_organisation.map do |code, latency|
            label = code || 'none'
            latency = latency.to_i
            Metric::Base.new('jobs.latency', latency, organisation: label) if latency > 10
          end.compact
        end

        def latencies_per_organisation
          Delayed::Job.from(jobs_with_age_and_organiastion_code).group(:organisation_code).maximum(:age)
        end

        def jobs_with_age_and_organiastion_code
          Delayed::Job.where('run_at < now()')
                      .joins('left join public.organisations on organisations.id = delayed_jobs.organisation_id')
                      .select('organisations.code as organisation_code', 'EXTRACT(SECOND FROM age(now(), run_at)) as age')
        end
      end
    end

    module Publisher
      # Publish metrics via Rails.logger (with a limit of a message per 30 seconds)
      class Log
        mattr_accessor :duration_between_messages, default: 1.minute
        mattr_accessor :logged_at

        def cool_down?
          logged_at.present? && logged_at > duration_between_messages.ago
        end

        def publish(metrics)
          return if cool_down?

          message = metrics.join(',')
          Rails.logger.info "[Delayed::Job] Metrics: #{message}"

          self.class.logged_at = Time.current
        end
      end

      # Publish metrics as statsd gauges
      class Datadog
        mattr_accessor :statsd, :service_name

        def publish(metrics)
          return unless statsd

          metrics.each do |metric|
            tags = metric.tags
            # Replace default service tag by worker service (ex: chouette-core-worker instead of chouette-core-front)
            tags = tags.merge(service: service_name) if service_name

            Rails.logger.debug { "[statsd] chouette.#{metric.name}=#{metric.value} tags: #{tags.inspect}" }
            statsd.gauge("chouette.#{metric.name}", metric.value, tags: tags)
          end
        end
      end
    end
  end
end
