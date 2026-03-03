# frozen_string_literal: true

module LongTransactionDetector
  def transaction(**options, &block)
    super do
      Logger.new(current_transaction).tagged do
        block.call
      end
    end
  end

  class Logger
    def initialize(current_transaction)
      @current_transaction = current_transaction
    end

    attr_reader :current_transaction

    mattr_reader :max_duration, default: ENV.fetch('CHOUETTE_LOG_LONG_TRANSACTIONS', '30').to_i

    def tagged(&block)
      with_new_tag do
        with_duration(&block)
      end
    end

    def with_duration
      value = nil
      transaction_start = Time.zone.now

      begin
        value = yield
      ensure
        transaction_end = Time.zone.now
        duration = transaction_end - transaction_start

        if duration > max_duration
          backtrace = caller.select { |path| path.start_with?(Rails.root.join('app').to_s) }
          Rails.logger.info "Long Transaction detected: #{current_transaction.uuid} - duration: #{duration}s, started_at: #{transaction_start}, caller: #{backtrace.inspect}"
        end
      end

      value
    end

    THREAD_VARIABLE_NAME = 'transaction_logger_last_tag'

    def last_tag
      Thread.current.thread_variable_get THREAD_VARIABLE_NAME
    end

    def save_tag
      Thread.current.thread_variable_set THREAD_VARIABLE_NAME, new_tag
    end

    def new_tag
      @new_tag ||= "T:#{current_transaction.uuid}"
    end

    def new_tag?
      new_tag != last_tag
    end

    def with_new_tag(&block)
      if new_tag?
        save_tag

        Rails.logger.tagged(new_tag, &block)
      else
        yield
      end
    end
  end
end

if ENV.key?('CHOUETTE_LOG_LONG_TRANSACTIONS')
  Rails.logger.debug "Enable log for transactions longer than #{ENV.fetch('CHOUETTE_LOG_LONG_TRANSACTIONS')}s"
  module ActiveRecord
    class Base
      class << self
        prepend LongTransactionDetector
      end
    end
  end
end
