module Chouette
  class Factory
    module Definition
      def define(&block)
        root.define(&block)
      end

      def root
        @root ||= Model.new(:root)
      end
    end
  end
end
