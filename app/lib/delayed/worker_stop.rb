# frozen_string_literal: true

module Delayed
  module WorkerStop
    def stop
      super

      Rails.logger.debug 'Remove Worker from database'
      @worker_model&.delete
    end
  end
end
