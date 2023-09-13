# frozen_string_literal: true

module Control
  class AttributeUniqueness < Control::Base
    module Options
      extend ActiveSupport::Concern

      included do
        option :target_model
        option :target_attribute
        option :uniqueness_scope

        enumerize :target_model, in: %w[Line StopArea Company VehicleJourney]
        enumerize :uniqueness_scope, in: %w[all workbench provider]

        validates :target_model, :target_attribute, presence: true

        def model_attribute
          candidate_target_attributes.find_by(model_name: target_model, name: target_attribute)
        end

        def candidate_target_attributes # rubocop:disable Metrics/MethodLength,Metrics/AbcSize
          Chouette::ModelAttribute.empty do # rubocop:disable Metrics/BlockLength
            # Chouette::StopArea
            define Chouette::StopArea, :name
            define Chouette::StopArea, :registration_number

            # Chouette::Company
            define Chouette::Company, :name
            define Chouette::Company, :registration_number
 
            # Chouette::Line
            define Chouette::Line, :name
            define Chouette::Line, :registration_number

            # Chouette::VehicleJourney
            define Chouette::VehicleJourney, :published_journey_name
            define Chouette::VehicleJourney, :published_journey_identifier
          end
        end

        def dataset_models
          %w[VehicleJourney]
        end
      end
    end
    include Options

    class Run < Control::Base::Run
      include Options

      def run
        analysis.duplicates.each do |duplicate|
          control_messages.create!({
            message_attributes: {
              name: duplicate.name,
              id: duplicate.external_id || duplicate.id,
              target_attribute: target_attribute
            },
            criticity: criticity,
            source_type: duplicate.source_type,
            source_id: duplicate.source_id,
            message_key: :attribute_uniqueness
          })
        end
      end

      def analysis
        Analysis.for(uniqueness_scope).new(context, target_model, target_attribute, model_attribute)
      end

      class Analysis
        def self.for(uniqueness_scope)
          return Nil unless uniqueness_scope

          const_get(uniqueness_scope.classify)
        end

        class Base
          def initialize(context, target_model, target_attribute, model_attribute)
            @context = context
            @target_model = target_model
            @target_attribute = target_attribute
            @model_attribute = model_attribute
          end

          attr_accessor :target_model, :target_attribute, :context, :model_attribute

          def duplicates
            PostgreSQLCursor::Cursor.new(query).map do |attributes|
              Duplicate.new attributes.merge source_type: source_type
            end
          end

          def model_singulier
            @model_singulier ||= target_model.underscore
          end

          def source_type
            @source_type ||= model_attribute.model_class.to_s
          end

          def model_collection
            @model_collection ||= model_singulier.pluralize
          end
    
          def sql_model_collection
            @sql_model_collection ||= public? ? "public.#{model_collection}" : model_collection
          end

          def models
            @models ||= context.send(model_collection)
          end

          def provider_id
            "#{model_collection}.#{model_singulier}_provider_id"
          end

          def query
            <<~SQL
              SELECT * FROM (
                SELECT #{model_collection}.*, #{duplicates_count} AS duplicates_count
                FROM #{sql_model_collection}
                WHERE #{model_collection}.id IN (#{models.select(:id).to_sql})
              ) AS with_duplicates_count
              WHERE duplicates_count > 1
            SQL
          end

          def lower_attribute
            "lower(#{model_collection}.#{target_attribute})"
          end

          def duplicates_count
            "count(#{model_collection}.id) OVER(PARTITION BY #{lower_attribute})"
          end

          def public?
            Apartment.excluded_models.include? source_type
          end
        end

        class Provider < Base
          def duplicates_count
            "count(#{model_collection}.id) OVER(PARTITION BY #{provider_id}, #{lower_attribute})"
          end
        end

        class Workbench < Base
          def duplicates_count
            "count(#{model_collection}.id) OVER(PARTITION BY workbenches.id, #{lower_attribute})"
          end

          def query
            <<~SQL
              SELECT * FROM (
                SELECT #{model_collection}.*, #{duplicates_count} AS duplicates_count
                FROM #{sql_model_collection}
                INNER JOIN public.#{model_singulier}_providers ON #{model_singulier}_providers.id = #{provider_id}
                INNER JOIN public.workbenches ON workbenches.id = #{model_singulier}_providers.workbench_id
                WHERE #{model_collection}.id IN (#{models.select(:id).to_sql})
              ) AS with_duplicates_count
              WHERE duplicates_count > 1
            SQL
          end
        end

        class All < Base
        
        end

        class Nil < All
        
        end

        class Duplicate
          def initialize(attributes)
            attributes.each { |k, v| send "#{k}=", v if respond_to?(k) }
          end

          attr_accessor :name, :id, :source_type, :published_journey_name,
                        :registration_number, :published_journey_identifier

          def external_id
            @registration_number || @published_journey_identifier
          end

          def source_id
            @id
          end

          def name
            @name || @published_journey_name
          end
        end
      end
    end
  end
end
