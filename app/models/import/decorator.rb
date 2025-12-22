# frozen_string_literal: true

module Import
  class Decorator < SimpleDelegator
    def initialize(resource, **attributes)
      super(resource)

      raise ArgumentError, 'No given resource' if resource.nil?

      attributes.each do |k, v|
        send("#{k}=", v)
      end
    end

    attr_accessor :lookup, :code_space

    alias resource __getobj__

    def errors
      @errors ||= Errors.new(resource)
    end

    class Errors < SimpleDelegator
      def initialize(resource)
        @errors = []
        super @errors

        @resource = resource
      end

      def add(message_key, **attributes)
        error = Import::Decorator::Error.new(message_key, **attributes)
        error.resource = @resource
        error.message_attributes[:resource_id] = @resource.id if @resource.respond_to?(:id)

        @errors << error
      end
    end

    def validate
      errors.clear
    end

    def valid?
      validate
      errors.empty?
    end

    class Error
      attr_accessor :message_key, :message_attributes, :resource, :criticity

      def initialize(message_key, **attributes)
        @message_key = message_key
        attributes.each { |k, v| send "#{k}=", v }
        @message_attributes ||= {}
      end
    end
  end
end
