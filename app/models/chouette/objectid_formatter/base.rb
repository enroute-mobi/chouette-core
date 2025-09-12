module Chouette
  module ObjectidFormatter
    class Base
      include ::ActiveRecord::Sanitization

      def table_name(model_class)
        model_class.table_name.split(".").last
      end

      def objectid(model)
      end
    end
  end
end
