# frozen_string_literal: true

module Macro
  class DefineAttributeFromParticulars < Macro::Base
    module Options
      extend ActiveSupport::Concern

      included do
        option :target_model
        option :target_attribute

        enumerize :target_model, in: %w[StopArea Company]
      end

      def model_attribute
        candidate_target_attributes.find_by(model_name: target_model, name: target_attribute)
      end

      def candidate_target_attributes # rubocop:disable Metrics/MethodLength
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

          # belongs_to are not supported by the macro
          exclude 'StopArea', :parent

          # Referent .. has no referent
          exclude 'StopArea', :referent
          exclude 'Company', :referent

          # Attributes use as criteria to create Stop Area Referent
          exclude 'StopArea', :coordinates
          exclude 'StopArea', :compass_bearing
        end
      end
    end

    validates :target_model, :target_attribute, :model_attribute, presence: true

    include Options

    class Run < Macro::Base::Run
      include Options

      def run
        referents_with_value.find_each do |referent|
          value = particular_values[referent.id]

          if referent.update(target_attribute => value)
            create_message referent, criticity: 'info'
          else
            create_message referent, criticity: 'warning', value: value
          end
        end
      end

      # Retrieve referents without target attribute in the macro scope
      def referents
        @referents ||= models.referents.where(target_attribute => nil)
      end

      # Retrieve all particulars associated to the referents (so in the whole scope)
      def particulars
        @particulars ||= macro_list_run.base_scope
                                       .send(model_collection)
                                       .particulars.where(referent: referents)
                                       .where.not(target_attribute => nil)
      end

      # Load (in memry :-/) only common value for particulars with the same referent
      def particular_values
        @particular_values ||= begin
          values = particulars.group(:referent_id)
                              .select(:referent_id, "array_agg(DISTINCT #{model_table}.#{target_attribute}) as values")

          # Uses a subquery to reject multiple values
          query = <<~SQL
            select referent_id_and_values.referent_id, referent_id_and_values.values[1]
            from (#{values.to_sql}) as referent_id_and_values
            where array_length(referent_id_and_values.values, 1) = 1;
          SQL

          Hash[ActiveRecord::Base.connection.select_rows(query)]
        end
      end

      def referents_with_value_ids
        particular_values.keys
      end

      # Referents with have a common value found
      def referents_with_value
        referents.where(id: referents_with_value_ids)
      end

      # "stop_areas", "companies", etc
      def model_collection
        @model_collection ||= model_attribute.model_class.model_name.plural
      end

      # "public.stop_areas", "public.companies", etc
      def model_table
        model_attribute.model_class.table_name
      end

      # stop_areas, companies, etc (which could be modified)
      def models
        @models ||= scope.send(model_collection)
      end

      def create_message(model, attributes, value = nil)
        attributes.merge!(
          message_attributes: { name: model.name, value: value },
          source: model
        )
        macro_messages.create!(attributes)
      end
    end
  end
end
