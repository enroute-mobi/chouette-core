module Chouette
  module ObjectidFormatter
    class StifNetex < Base

      def short_id_sql_expr(model_class)
        "lower(split_part(split_part(#{table_name(model_class)}.objectid, ':', 3), '-', 1))"
      end

      PENDING_PATTERN = "__pending_id__"

      def before_validation(model)
        model.objectid = "#{PENDING_PATTERN}#{SecureRandom.uuid}"
      end

      def after_commit(model)
        return unless model.persisted?
        return unless model.objectid&.starts_with?(PENDING_PATTERN)

        oid = objectid(model)
        model.update_column(:objectid, oid.to_s) if oid.valid?
      end

      def objectid(model)
        Chouette::Objectid::StifNetex.new(provider_id: model.referential.prefix, object_type: model.class.name.gsub('Chouette::',''), local_id: model.local_id)
      end

      def get_objectid(definition)
        parts = definition.try(:split, ":")
        Chouette::Objectid::StifNetex.new(provider_id: parts[0], object_type: parts[1], local_id: parts[2], creation_id: parts[3])
      end
    end
  end
end
