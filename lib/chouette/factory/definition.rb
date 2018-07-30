module Chouette
  module Factory
    module Definition
      def define(&block)
        root.define &block
        puts root.inspect
      end

      @@root = nil
      def root
        @@root ||= Model.new(:root)
      end
    end
  end
end
