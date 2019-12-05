module Chouette
  module Benchmark
    def self.log(step, &block)
      result = nil
      memory_before = current_usage

      time = ::Benchmark.realtime do
        result = yield
      end

      memory_after = current_usage
      Rails.logger.info "#{step} operation : #{time} seconds / memory delta #{memory_after - memory_before} (#{memory_before} > #{memory_after})"

      result
    end

    KERNEL_PAGE_SIZE = `getconf PAGESIZE`.chomp.to_i rescue 4096
    STATM_PATH       = "/proc/#{Process.pid}/statm"
    STATM_FOUND      = File.exist?(STATM_PATH)

    def self.current_usage
      STATM_FOUND ? (File.read(STATM_PATH).split(' ')[1].to_i * KERNEL_PAGE_SIZE) / 1024 / 1024.0 : 0
    end

  end
end
