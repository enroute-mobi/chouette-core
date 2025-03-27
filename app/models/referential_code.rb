# frozen_string_literal: true

class ReferentialCode < AbstractCode
  class << self
    def model_name
      @_model_name ||= super.tap do |model_name| # rubocop:disable Naming/MemoizedInstanceVariableName
        model_name.instance_variable_set(:@i18n_key, 'code')
      end
    end
  end
end
