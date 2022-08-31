module Macro
  class DefineAttributeDefaultValue < Macro::Base
    module Options
      extend ActiveSupport::Concern

      included do
        option :target_model
				option :model_attribute_name

        enumerize :target_model, in: %w[StopArea Company]

        validates :target_model, :model_attribute_name, presence: true
      end
    end

    include Options

    class Run < Macro::Base::Run
      include Options

      def run
        referents.find_each do |referent|
          values = particular_values[referent.id]

          next if values.many?

          value = values.first

          if referent.update Hash[model_attribute_name, value] 
            create_message referent, criticity: 'info'
          else 
            create_message referent, criticity: 'warning', value: value
          end
        end
      end

      def create_message(model, attributes, value = nil)
        attributes.merge!(
          message_attributes: { name: model.name, value: value },
          source: model
        )
        macro_messages.create!(attributes)
      end

      def model_collection
        @model_collection ||= target_model.underscore.pluralize
      end

      def scope
        # All Participants in the Workgroup must be used
        CustomScope.new(self).scope(macro_list_run.base_scope)
      end

      def models
        @models ||= scope.send(model_collection)
      end

      def particulars
        @particulars ||= models.particulars.joins(:referent)
      end

      def referents
        @referents ||= models.referents.where(Hash[model_attribute_name, nil])
      end

      def particular_values
        entries = particulars
          .where.not(Hash[model_attribute_name, nil])
          .group(:referent_id)
          .pluck(:referent_id, "array_agg(DISTINCT #{model_collection}.#{model_attribute_name})")

          Hash[entries]
      end
    end
  end
end
