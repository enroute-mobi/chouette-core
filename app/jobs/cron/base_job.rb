# frozen_string_literal: true

module Cron
  class BaseJob
    class_attribute :cron_expression

    class << self
      attr_accessor :abstract_class

      def abstract_class?
        defined?(@abstract_class) && @abstract_class == true
      end

      def cron(cron_expression)
        self.cron_expression = cron_expression
      end

      # redefine this method to return false to remove a cron job
      def enabled
        true
      end

      def schedule
        return if scheduled?

        dj = delayed_job
        if dj
          dj.update(cron: cron_expression)
        else
          ::Delayed::Job.enqueue(new, cron: cron_expression)
        end
      end

      def remove
        delayed_job.destroy if scheduled?
      end

      def schedule_all
        load_all_subclasses

        descendants.each do |job_class|
          next if job_class.abstract_class?

          if job_class.enabled
            job_class.schedule
          else
            job_class.remove
          end
        end
      end

      def scheduled?
        dj = delayed_job
        !dj.nil? && dj.cron == cron_expression
      end

      def delayed_job
        ::Delayed::Job.where(handler: "--- !ruby/object:#{name} {}\n").first
      end

      def cron_name
        name.demodulize[0...-3]
      end

      private

      def load_all_subclasses
        # Need to load all jobs definitions in order to find subclasses
        glob = Rails.root.join('app/jobs/cron/**/*_job.rb')
        Dir.glob(glob).sort.each do |file|
          require file
        end
      end
    end

    self.abstract_class = true

    def perform
      perform_once
    rescue StandardError => e
      ::Chouette::Safe.capture("#{self.class.cron_name} Cron Job failed", e)
    end

    # this method HAS TO be redefined in subclasses
    def perform_once
      raise NotImplementedError
    end
  end
end
