# frozen_string_literal: true

module Policy
  # Base class for Policy implementations
  #
  # If a non-standard action is added, the check must be wrapped by #around_can:
  #
  #   def something?
  #     around_can(:something) { true || false }
  #   end
  #
  # If that new action directly calls the context, .context_class(action) must return a context class that supports it.
  #
  #   def something?
  #     around_can(:something) { context.workgroup.nil? }
  #   end
  #
  #   def self.context_class(action)
  #     if action == :something
  #       ::Policy::Context::Workgroup
  #     else
  #       super
  #     end
  #   end
  class Base
    class << self
      def strategy_classes
        @strategy_classes ||= {}
      end

      def authorize_by(strategy_class, **options) # rubocop:disable Metrics/AbcSize
        include strategy_class::PolicyConcern if strategy_class.constants.include?(:PolicyConcern)

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

      def context_class(action)
        @context_classes ||= Hash.new { |h, v| h[v] = context_class_for(v) }
        @context_classes[action]
      end

      private

      def context_class_for(action)
        context_class = action.nil? ? nil : context_class(nil)
        strategy_classes[action]&.each do |s|
          next unless s.context_class

          context_class = s.context_class if context_class.nil? || s.context_class < context_class
        end
        context_class
      end

      def inherited(base)
        if instance_variable_defined?(:@strategy_classes)
          base.instance_variable_set(:@strategy_classes, @strategy_classes.transform_values(&:dup))
        end

        super
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
      (check_context_class(action, *args) && apply_strategies(action, *args) && yield).tap do |result|
        log(action, *args) { "= #{result.inspect}" }
      end
    end

    def check_context_class(action, *args)
      context_class = self.class.context_class(action)
      return true if context_class.nil?
      return true if context && context.class <= context_class

      log(action, *args) do
        "context #{context&.class.inspect} is incompatible with #{context_class}"
      end
      false
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

    def log(action, *args, &content) # rubocop:disable Metrics/AbcSize
      return unless Rails.logger.debug?

      resource_description = resource.class.to_s
      resource_description += "##{resource.id}" if resource.respond_to?(:id)

      description = action.to_s
      description += " #{args.join(', ')}" if args.any?

      s = "[Policy] #{self.class.name['Policy::'.length..]} #{resource_description} #{description} #{content.call}"
      Rails.logger.debug(s)
    end
  end
end
