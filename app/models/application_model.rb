class ApplicationModel < ::ActiveRecord::Base
  include MetadataSupport
  include ReferentialIndexSupport

  self.abstract_class = true

  class << self
    def clean!
      Rails.logger.warn "Default clean! uses destroy_all on #{name}#clean!"
      destroy_all
    end

    def skip_objectid_uniqueness?
      @skip_objectid_uniqueness
    end

    def skipping_objectid_uniqueness
      @skip_objectid_uniqueness = true
      yield
      @skip_objectid_uniqueness = false
    end

    def add_light_belongs_to(rel_name)
      rel = reflections[rel_name.to_s]
      raise "missing relation #{rel_name} on #{self.name}" unless rel

      belongs_to "#{rel_name}_light".to_sym, ->{ light }, class_name: rel.klass.name, foreign_key: rel.foreign_key

      alias_method "#{rel_name}_light_without_cache", "#{rel_name}_light"
      define_method "#{rel_name}_light_with_cache" do
        association(rel_name).loaded? ? send(rel_name) : send("#{rel_name}_light_without_cache")
      end
      alias_method "#{rel_name}_light", "#{rel_name}_light_with_cache"
    end
  end

  def jobs_queue
    return :long_jobs if self.is_a?(Import::Base)
    return :long_jobs if self.is_a?(Export::Base)
    return :long_jobs if self.is_a?(Merge)
    return :long_jobs if self.is_a?(Aggregate)

    :default
  end

  def enqueue_job method, args=[], max_attempts: 1, run_at: nil
    job = LongRunningJob.new(self, method, args)
    job.max_attempts = max_attempts

    Delayed::Job.enqueue job, queue: jobs_queue, run_at: run_at
  end
end
