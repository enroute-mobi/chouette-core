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
        enumerize :uniqueness_scope, in: %w[workgroup workbench provider referential]

        validates :target_model, :target_attribute, presence: true

        before_update :reset_options

        def model_attribute
          candidate_target_attributes.find_by(model_name: target_model, name: target_attribute)
        end

        def candidate_target_attributes
          Chouette::ModelAttribute.collection do
            # Chouette::StopArea
            select Chouette::StopArea, :name
            select Chouette::StopArea, :registration_number
            # Chouette::Company
            select Chouette::Company, :name
            select Chouette::Company, :registration_number
            # Chouette::Line
            select Chouette::Line, :name
            select Chouette::Line, :registration_number
            # Chouette::VehicleJourney
            select Chouette::VehicleJourney, :published_journey_name
            select Chouette::VehicleJourney, :published_journey_identifier
          end
        end

        def dataset_models
          %w[VehicleJourney]
        end

        def reset_options
          return unless target_model.in?(dataset_models)

          self.options = self.options.except('uniqueness_scope')
        end
      end
    end
    include Options

    class Run < Control::Base::Run
      include Options

      def run
        analysis.duplicates.each do |duplicate|
          create_message(duplicate)
        end
      end

      def create_message(duplicate)
        control_messages.create!(
          message_attributes: {
            id: duplicate.external_id || duplicate.id,
            name: duplicate.name, target_attribute: target_attribute
          },
          criticity: criticity, message_key: :attribute_uniqueness,
          source_id: duplicate.source_id, source_type: duplicate.source_type
        )
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

          PREFIX_PROVIDERS = {
            stop_area: 'stop_area',
            line: 'line',
            company: 'line'
          }.with_indifferent_access

          def duplicates
            PostgreSQLCursor::Cursor.new(query).map do |attributes|
              Duplicate.new attributes.merge source_type: source_type
            end
          end

          def singular_model
            @singular_model ||= target_model.underscore
          end

          def source_type
            @source_type ||= model_attribute.model_class.to_s
          end

          def model_collection
            @model_collection ||= singular_model.pluralize
          end

          def table_name
            @table_name ||= model_attribute.model_class.table_name
          end

          def models
            @models ||= context.send(model_collection)
          end

          def where
            "WHERE #{table_name}.id IN (#{models.select(:id).to_sql})"
          end

          def provider_id
            "#{model_collection}.#{PREFIX_PROVIDERS[singular_model]}_provider_id"
          end

          def providers
            "#{PREFIX_PROVIDERS[singular_model]}_providers"
          end

          def query
            <<~SQL
              SELECT * FROM (
                SELECT #{table_name}.*, #{duplicates_count} AS duplicates_count
                FROM #{table_name}
                #{inner_join}
                #{where}
              ) AS with_duplicates_count
              WHERE duplicates_count > 1
            SQL
          end

          def lower_attribute
            "lower(#{model_collection}.#{target_attribute})"
          end

          def inner_join; end

          def duplicates_count; end

          class Duplicate
            def initialize(attributes)
              attributes.each { |k, v| send "#{k}=", v if respond_to?(k) }
            end

            attr_writer   :name
            attr_accessor :registration_number, :published_journey_name,
                          :id, :source_type, :published_journey_identifier

            alias source_id id

            def external_id
              @registration_number || @published_journey_identifier
            end

            def name
              @name || @published_journey_name
            end
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

          def inner_join
            <<~SQL
              INNER JOIN public.#{providers} ON #{providers}.id = #{provider_id}
              INNER JOIN public.workbenches ON workbenches.id = #{providers}.workbench_id
            SQL
          end
        end

        class Workgroup < Base
          def duplicates_count
            "count(#{model_collection}.id) OVER(PARTITION BY workgroups.id, #{lower_attribute})"
          end

          def where
            "WHERE public.workgroups.id = #{workgroup_id}"
          end

          def inner_join
            <<~SQL
              INNER JOIN public.#{providers} ON #{providers}.id = #{provider_id}
              INNER JOIN public.workbenches ON workbenches.id = #{providers}.workbench_id
              INNER JOIN public.workgroups ON workgroups.id = workbenches.workgroup_id
            SQL
          end

          def workgroup_id
            context.workgroup.id
          end
        end

        class Referential < Base
          def duplicates_count
            "count(#{model_collection}.id) OVER(PARTITION BY #{lower_attribute})"
          end
        end

        class Nil < Referential; end
      end
    end
  end
end
