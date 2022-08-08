module Control
  class ModelStatus < Control::Base

    module Options
      extend ActiveSupport::Concern

      included do
        enumerize :target_model, in: %w{ Line StopArea }
        enumerize :expected_status, in: %w{ enabled disabled }

        option :target_model
        option :expected_status

        validates :target_model, :expected_status, presence: true
      end
    end
    include Options

    class Run < Control::Base::Run
      include Options

      def run
        faulty_models.find_each do |model|
          control_messages.create({
            message_attributes: {
              name: model.try(:name) || model.id,
              expected_status: I18n.t("enumerize.expected_status.#{expected_status}")
            },
            criticity: criticity,
            source: model,
            message_key: :model_status
          })
        end
      end

      module Status
        class Base
          def initialize(models)
            @models = models
          end
          attr_accessor :models
        end

        class StopArea < Base
          def enabled
            models
              .where(deleted_at: nil)
              .where.not(confirmed_at: nil)
          end

          def disabled
            models.where.not(deleted_at: nil)
          end
        end

        class Line < Base
          def enabled
            models.where(deactivated: false)
          end

          def disabled
            models.where(deactivated: true)
          end

        end
      end

      def faulty_models
        status_klass.send(faulty_status)
      end

      def faulty_status
        if expected_status == 'enabled'
          'disabled'
        else
          'enabled'
        end
      end

      def status_klass
        @status_klass ||= Run::Status.const_get("#{target_model}").new models
      end

      def model_collection
        @model_collection ||= target_model.underscore.pluralize.to_sym
      end

      def models
        @models ||= context.send(model_collection)
      end
    end
  end
end