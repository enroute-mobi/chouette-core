module Chouette
  module ObjectidFormatter
    class Netex < Base

      def short_id_sql_expr(model_class)
        "lower(split_part(split_part(#{table_name(model_class)}.objectid, ':', 3), '-', 1))"
      end

      def before_validation(model)
        oid = objectid(model)
        model.objectid = oid.to_s if oid.valid?
      end

      def after_commit(model)
        # unused method in this context
      end

      def objectid(model)
        Chouette::Objectid::Netex.new(local_id: SecureRandom.uuid, object_type: model.class.name.gsub('Chouette::',''))
      end

      def get_objectid(definition)
        parts = definition.try(:split, ":")
        Chouette::Objectid::Netex.new(provider_id: parts[0], object_type: parts[1], local_id: parts[2], creation_id: parts[3])
      end
    end
  end
end
