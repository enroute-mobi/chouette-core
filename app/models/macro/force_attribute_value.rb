# frozen_string_literal: true

module Macro
  class ForceAttributeValue < Macro::Base
    module Options
      extend ActiveSupport::Concern

      included do
        option :target_model
        option :target_attribute
        option :expected_value

        enumerize :target_model, in: %w[StopArea Company Line Entrance PointOfInterest]

        validates :target_model, :target_attribute, :model_attribute, :expected_value, presence: true
      end

      def model_attribute
        candidate_target_attributes.find_by(model_name: target_model, name: target_attribute)
      end

      def candidate_target_attributes
        Chouette::ModelAttribute.collection do

          # Chouette::Company
          select Chouette::Company, :is_referent
          select Chouette::Company, :town

          # Chouette::StopArea
          select Chouette::StopArea, :city_name
          select Chouette::StopArea, :is_referent

          # Line
          select Chouette::Line, :is_referent

          # Entrance
          select Entrance, :city_name

          # PointOfInterest
          select PointOfInterest::Base, :city_name
        end
      end
    end

    include Options

    class Run < Macro::Base::Run
      include Options

      def run
        candidate_models.find_each do |model|
          model.update(target_attribute => expected_value)
          create_message model, target_attribute
        end
      end

      def create_message(model, target_attribute)
        attributes = {
          message_attributes: {
            name: model.name, 
            target_attribute: target_attribute
          },
          source: model
        }

        attributes.merge!(criticity: 'error', message_key: 'error') unless model.valid?

        macro_messages.create!(attributes)
      end

      def candidate_models
        @candidate_models ||= models.where.not(id: models.where(target_attribute => expected_value))  
      end

      def model_collection
        @model_collection ||= model_attribute.model_class.model_name.plural
      end

      def models
        @models ||= scope.send(model_collection)
      end
    end
  end
end
