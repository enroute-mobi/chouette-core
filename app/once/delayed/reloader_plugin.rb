# frozen_string_literal: true

module Delayed
  # Reload application only when a new job starts
  # See https://github.com/collectiveidea/delayed_job/pull/1115
  class ReloaderPlugin < Plugin
    callbacks do |lifecycle|
      lifecycle.around(:invoke_job) do |_job, *_args, &block|
        ::Rails.application.reloader.wrap do
          Rails.logger.debug 'Reloaded code'
          block.call
        end
      end
    end
  end
end
