# frozen_string_literal: true

# Use a predictable local file for a CarrierWave Uploader
module LocalCache
  def local_cache!
    with_local_lock do
      unless local_cached?
        Rails.logger.info "Cache locally file for #{model.class}##{model.id} in #{local_cache_file}" if model
        cache!
      end
    end

    LocalCache.clean_local_cache
  end

  def local_cached?
    return true if file_storage?

    File.exist? local_cache_file
  end

  def local_cache_file
    @local_cache_file ||=
      begin
        uniq_part = Digest::SHA1.hexdigest(path)
        # The file must have an authorized extension :(
        original_filename = File.basename(path)
        File.join(local_cache_directory, "#{uniq_part}-#{original_filename}")
      end
  end

  # Use by #cache! method
  def cache_path(_for_file = nil)
    local_cache_file
  end

  def lock_file
    "#{local_cache_file}.lock"
  end

  def with_local_lock
    # Lock mechanism could be disable in dev/test environment,
    # but we want to test it

    File.open(lock_file, 'w') do |lock|
      Rails.logger.debug "Lock #{lock_file}"
      lock.flock(File::LOCK_EX)
      yield
    end
  end

  def file_storage?
    file.is_a?(CarrierWave::SanitizedFile)
  end

  # We can't use the CarrierWave cache directory which expects a given format for cleaning
  # In a container environment, this directory will be uniq
  mattr_accessor :local_cache_directory, default: Dir.mktmpdir('chouette-local-cache')

  mattr_accessor :local_cache_cleaned_at, default: Time.zone.now

  def self.clean_local_cache
    return if local_cache_cleaned_at > 5.minutes.ago

    Rails.logger.debug 'Clean local cache'
    self.local_cache_cleaned_at = Time.zone.now

    Dir.glob(File.join(local_cache_directory, '*')).each do |file|
      created_at = File.ctime(file)
      next if created_at > 24.hours.ago

      Rails.logger.info "Cache locally file #{file}"
      File.delete file
    end
  end
end
