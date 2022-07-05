#
# Allow to wrap a method which will be provided by subclasses:
#
#   class Example
#     extend AroundMethod
#     around_method :sample
#
#     def around_sample(&block)
#       puts "Before"
#       block.call
#       puts "After"
#     end
#   end
#
#   class Child < Example
#     def sample
#       puts "Child sample"
#     end
#   end
#
module AroundMethod
  extend ActiveSupport::Concern

  included do
    class_attribute :around_methods, default: {}
  end

  class_methods do
    def method_added(method_name)
      self.around_methods[method_name]&.setup(self) if self.around_methods
      super method_name
    end

    def around_method(*names)
      names.each do |name|
        self.around_methods = around_methods.merge(name.to_sym => Method.new(name))
      end
    end
  end

  class Method

    def initialize(name)
      @name = name
      @setup_classes = Set.new
    end
    attr_reader :name

    def protected_method
      "protected_#{name}"
    end

    def setup(klass)
      return unless @setup_classes.add?(klass)

      original = klass.instance_method name
      method_name = name

      klass.define_method(protected_method) do |*args, &block|
        send "around_#{method_name}"  do
          original.bind(self).call(*args, &block)
        end
      end
      klass.alias_method name, protected_method
    end
  end

end
