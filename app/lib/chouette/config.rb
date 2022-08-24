# frozen_string_literal: true

module Chouette
  class Config
    class Error < StandardError; end

    class << self
      def load
        if ENV['SKIP_CONFIG'] == 'true'
          puts 'Skip config loading'
          return
        end

        @instance = Config.new.tap do |config|
          # config.log if config.production?
        end
      end

      attr_reader :instance

      def loaded?
        @instance.present?
      end

      def method_missing(name, *arguments)
        return instance.send name, *arguments if instance && instance.respond_to?(name)

        super
      end
    end

    def initialize(environment = ENV)
      @env = Environment.new(environment)
    end

    def subscription
      @subscription ||= Subscription.new(env)
    end

    # See Feature.additionals
    def additional_features
      @additional_features ||= env.array('FEATURES_ADDITIONAL')
    end

    class Subscription
      def initialize(env)
        @env = env
      end
      attr_reader :env

      def enabled?
        env.boolean('ACCEPT_USER_CREATION') ||
          env.boolean('SUBSCRIPTION_ENABLED') ||
          default_enabled?
      end

      def default_enabled?
        !env.production?
      end

      def notification_recipients
        env.array('SUBSCRIPTION_NOTIFICATION_RECIPIENTS')
      end
    end

    class Environment
      def initialize(values = ENV)
        @values = values
      end

      delegate :development?, :test?, :production?, to: :rails_env

      def rails_env
        # Do not use Rails.env to simplify tests
        @rails_env ||= ActiveSupport::StringInquirer.new(value('RAILS_ENV'))
      end

      def value(name)
        @values["CHOUETTE_#{name}"] || @values[name]
      end

      BOOLEAN_VALUES = %w[true TRUE 1].freeze
      def boolean(name)
        BOOLEAN_VALUES.include? value(name)
      end

      def array(name)
        raw_value = value(name)
        return [] unless raw_value

        raw_value.split(',')
      end
    end

    private

    attr_reader :env
  end
end
