# frozen_string_literal: true

module Policy
  # Base class for Policy implementations
  #
  # If a non-standard action is added, the check must be wrapped by #around_can:
  #
  #   def something?
  #     around_can(:something) { true || false }
  #   end
  class Base
    class << self
      def strategy_classes
        @strategy_classes ||= {}
      end

      def authorize_by(strategy_class, **options)
        if options[:only]
          options[:only].each do |action|
            strategy_classes[action] ||= []
            strategy_classes[action] << strategy_class
          end
        else
          strategy_classes[nil] ||= []
          strategy_classes[nil] << strategy_class
        end
      end
    end

    def initialize(resource, context: nil)
      @resource = resource
      @context = context
    end

    attr_reader :resource, :context

    def strategies
      @strategies ||= self.class.strategy_classes.transform_values { |v| v.map { |k| k.new(self) } }
    end

    def create?(resource_class)
      around_can(:create, resource_class) { _create?(resource_class) }
    end
    alias new? create?

    def update?
      around_can(:update) { _update? }
    end
    alias edit? update?

    def destroy?
      around_can(:destroy) { _destroy? }
    end

    def can?(action, *args)
      around_can(action, *args) { _can?(action, *args) }
    end

    def method_missing(name, *arguments, **_options, &block)
      return can?(name.to_s[0..-2].to_sym, *arguments) if name.end_with?('?')

      super
    end

    def respond_to_missing?(name, include_private)
      return true if name.end_with?('?')

      super
    end

    protected

    def _can?(_action, *_args)
      # TODO: See CHOUETTE-3346
      false
    end

    def _create?(resource_class)
      _can?(:create, resource_class)
    end

    def _update?
      _can?(:update)
    end

    def _destroy?
      _can?(:destroy)
    end

    private

    def around_can(action, *args)
      (apply_strategies(action, *args) && yield).tap do |result|
        log(action, *args) { "= #{result.inspect}" }
      end
    end

    def apply_strategies(action, *args)
      apply_strategies_for(nil, action, *args) && apply_strategies_for(action, action, *args)
    end

    def apply_strategies_for(key, action, *args)
      return true unless strategies.key?(key)

      strategies[key].all? do |s|
        s.apply(action, *args).tap do |result|
          log(action, *args) { "halted by #{s.class.name}" } unless result
        end
      end
    end

    def log(action, *args, &content)
      return unless Rails.logger.debug?

      resource_description = "#{resource.class.name}##{resource.try(:id)}"

      description = action.to_s
      description += " #{args.join(', ')}" if args.any?

      Rails.logger.debug "[Policy] #{self.class.name.demodulize} #{resource_description} #{description} #{content.call}"
    end
  end
end
