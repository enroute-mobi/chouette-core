# frozen_string_literal: true

module Chouette
  module ObjectidFormatter
    # Creates Referential models objectid by using IBOO specific format
    class StifNetex < Base
      PENDING_PATTERN = '__pending_id__'

      def before_validation(model)
        return if model.raw_objectid

        model.objectid =
          model.id ? objectid(model).to_s : pending_id
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
        parts = definition.try(:split, ':')
        Chouette::Objectid::StifNetex.new(
          provider_id: parts[0],
          object_type: parts[1],
          local_id: parts[2],
          creation_id: parts[3]
        )
      end

      module Generator
        def self.for(model)
          case model
          when Chouette::StopPoint
            StopPoint.new(model)
          when Chouette::TimeTable
            TimeTable.new(model)
          else
            Base.new(model)
          end
        end

        class Base < SimpleDelegator
          def referential_id
            transient(:referential_id) || referential&.id
          end

          def referential_prefix
            transient(:referential_prefix) || referential&.prefix
          end

          def line_code
            transient(:line_code) || line&.get_objectid&.local_id
          end

          def line
            return __getobj__.line if __getobj__.respond_to?(:line)

            route&.line
          end

          def local_id_parts
            [referential_id, line_code, id]
          end

          def local_id
            parts = local_id_parts
            return nil if parts.any?(&:blank?)

            ['local', *parts].join('-')
          end

          def object_type
            __getobj__.class.name.gsub('Chouette::', '')
          end

          def provider_id
            referential_prefix
          end

          def objectid
            attributes = {
              provider_id: provider_id,
              object_type: object_type,
              local_id: local_id
            }
            return nil if attributes.any? { |_k, v| v.nil? }

            Chouette::Objectid::StifNetex.new(**attributes)
          end
        end

        class StopPoint < Base
          def local_id_parts
            [referential_id, line_code, route_id, id]
          end
        end

        class TimeTable < Base
          def local_id_parts
            [referential_id, id]
          end
        end
      end
    end
  end
end
