# frozen_string_literal: true

module Chouette
  module ObjectidFormatter
    class StifCodifligne < Base
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
        parts = definition.try(:split, ":")

        if parts.size == 3 || parts[3] == 'LOC'
          # V2
          Chouette::Objectid::StifCodifligne.new(provider_id: parts[0], object_type: parts[1], local_id: parts[2], local_marker: parts[3])
        else
          Chouette::Objectid::StifCodifligne.new(provider_id: parts[0], sync_id: parts[1], object_type: parts[2], local_id: parts[3])
        end
      end

      module Generator
        def self.for(model)
          case model
          when ::BookingArrangement
            BookingArrangement.new(model)
          else
            Base.new(model)
          end
        end

        class Base < SimpleDelegator
          def provider_id
            'chouette'
          end

          def object_type
            __getobj__.class.name
          end

          def local_id
            SecureRandom.uuid
          end

          def local_marker
            'LOC'
          end

          def objectid
            attributes = {
              provider_id: provider_id,
              object_type: object_type,
              local_id: local_id,
              local_marker: local_marker
            }
            return nil if attributes.any? { |_k, v| v.nil? }

            Chouette::Objectid::StifCodifligne.new(**attributes)
          end
        end

        class BookingArrangement < Base
          def provider_id
            line_provider.workbench.organisation.code
          end
        end
      end
    end
  end
end
