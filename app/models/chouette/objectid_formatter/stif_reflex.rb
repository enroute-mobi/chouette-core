module Chouette
  module ObjectidFormatter
    class StifReflex < Base
      PENDING_PATTERN = '__pending_id__'

      def before_validation(model)
        return if model.raw_objectid

        model.objectid = model.id ? objectid(model).to_s : pending_id
      end

      def pending_id
        "#{PENDING_PATTERN}#{SecureRandom.uuid}"
      end

      def after_commit(model)
        return unless model.persisted?
        return unless model.raw_objectid&.starts_with?(PENDING_PATTERN)

        oid = objectid(model)
        model.update_column(:objectid, oid.to_s) if oid.valid? # rubocop:disable Rails/SkipsModelValidations
      end

      def objectid(model)
        Generator.for(model).objectid
      end

      def get_objectid(definition)
        parts = definition.try(:split, ":", -1)

        if parts.size == 4 && parts[3].blank?
          Chouette::Objectid::StifReflex.new(provider_id: parts[0], object_type: parts[1], local_id: parts[2])
        elsif parts.size == 5
          Chouette::Objectid::StifReflex.new(country_code: parts[0], object_type: parts[2], local_id: parts[3], provider_id: parts[4])
        else
          Chouette::Objectid::StifReflex.new()
        end
      end

      module Generator
        def self.for(model)
          case model
          when ::Chouette::StopArea
            if model.area_type.flexible_stop_place?
              FlexibleStopPlace.new(model)
            else
              Base.new(model)
            end
          else
            Base.new(model)
          end
        end

        class Base < SimpleDelegator
          def country_code
            'FR'
          end

          def object_type
            __getobj__.class.name.gsub('Chouette::', '')
          end

          def local_id
            __getobj__.id.to_s
          end

          def provider_id
            'FR1'
          end

          def objectid
            attributes = {
              country_code: country_code,
              object_type: object_type,
              local_id: local_id,
              provider_id: provider_id
            }
            return nil if attributes.any? { |_k, v| v.nil? }

            Chouette::Objectid::StifReflex.new(**attributes)
          end
        end

        class FlexibleStopPlace < Base
          def object_type
            'FlexibleStopPlace'
          end
        end
      end
    end
  end
end
