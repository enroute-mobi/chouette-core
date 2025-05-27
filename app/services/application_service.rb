# frozen_string_literal: true

class ApplicationService
  def self.call(*args, **options, &block)
    new(*args, **options, &block).call
  end
end
