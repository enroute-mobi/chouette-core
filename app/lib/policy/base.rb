# frozen_string_literal: true

module Policy
  # Base class for Policy implementations
  class Base
    def initialize(resource, context: nil)
      @resource = resource
      @context = context
    end

    attr_reader :resource, :context

    def create?(_resource_class)
      false
    end
    alias new? create?

    def update?
      false
    end
    alias edit? update?

    def destroy?
      false
    end

    include AroundMethod
    around_method :can?

    def around_can?(name, *arguments, &block)
      block.call(*arguments).tap do |result|
        resource_description = "#{resource.class.name}##{resource.try(:id)}"

        description = name.to_s
        description += " #{arguments.first}" if name == :create

        Rails.logger.debug "[Policy] #{self.class.name.demodulize} #{resource_description} #{description} = #{result}"
      end
    end

    def can?(_action, *_arguments)
      # TODO: See CHOUETTE-3346
      false
    end

    def method_missing(name, *arguments)
      return can?(name.to_s[0..-2].to_sym, *arguments) if name.end_with?('?')

      super
    end

    def respond_to_missing?(name, include_private)
      return true if name.end_with?('?')

      super
    end
  end
end
