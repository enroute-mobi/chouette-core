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

    def candidate_target_attributes
      Chouette::ModelAttribute.for(self.class.target_model.values) do
        # Name attribute is always already defined
        # The macro can't find referents without name
        exclude 'StopArea', :name
        exclude 'Company', :name

        # Status attribute is always already defined
        # The macro can't find referents without status
        exclude 'StopArea', :status

        # The current registration number uniqueness makes it impossible
        exclude 'StopArea', :registration_number

        # Referent .. has no referent
        exclude 'StopArea', :referent
        exclude 'Company', :referent

        # Attributes use as criteria to create Stop Area Referent
        exclude 'StopArea', :coordinates
        exclude 'StopArea', :compass_bearing
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
