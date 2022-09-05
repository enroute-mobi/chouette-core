# frozen

# Provides shortcuts to use Chouette::Benchmark measure method in a Ruby class.
#
# To measure a given block:
#
#   def foo
#      measure "foo", target: target.id do
#        # ...
#      end
#   end
#
# To measure a existing method:
#
#   def foo
#     # ...
#   end
#   measure :foo
#   measure :foo, as: 'bar'
#   measure :foo, as: ->(part) { part.class.name.demodulize }
module Measurable
  extend ActiveSupport::Concern

  # Measure the given block with the given options
  def measure(*args, &block)
    Chouette::Benchmark.measure(*args, &block)
  end

  class_methods do
    # Use #measure when the given methods are invoked
    def measure(*method_names, as: nil) # rubocop:disable Naming/MethodParameterName
      proxy = Module.new do
        method_names.each do |name|
          Method.new(self, name, as: as).measure
        end
      end

      prepend proxy
    end
  end

  # Prepares measurement of a given method
  class Method
    def initialize(proxy, name, as: nil) # rubocop:disable Naming/MethodParameterName
      @proxy = proxy
      @name = name
      @as = as
    end
    attr_reader :proxy, :name, :as

    def alias_name(instance)
      as.respond_to?(:call) ? as.call(instance) : as
    end

    def measure_name(instance)
      (alias_name(instance) || name).to_s
    end

    def measure
      # Need a local variable to be invoked in define_method
      method = self
      proxy.define_method name do |*args, &block|
        measure(method.measure_name(self)) { super(*args, &block) }
      end
    end
  end
end
