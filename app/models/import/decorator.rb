# frozen_string_literal: true

module Import
  class Decorator < SimpleDelegator
    def initialize(resource, **attributes)
      super(resource)
      attributes.each do |k, v|
        send("#{k}=", v)
      end
    end

    attr_accessor :lookup, :code_space

    alias resource __getobj__

    def errors
      @errors ||= Errors.new
    end

    class Errors < SimpleDelegator
      def initialize
        @errors = []
        super @errors
      end

      def add(message_key, **attributes)
        @errors << Import::Decorator::Error.new(message_key, **attributes)
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
      attr_accessor :message_key, :message_attributes, :criticity

      def initialize(message_key, **attributes)
        @message_key = message_key
        attributes.each { |k, v| send "#{k}=", v }
      end
    end
  end
end
