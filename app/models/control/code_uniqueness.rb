# frozen_string_literal: true

module Control
  class CodeUniqueness < Control::Base
    module Options
      extend ActiveSupport::Concern

      included do
        option :target_model
        option :target_code_space_id
        option :uniqueness_scope

        enumerize :target_model, in: %w[StopArea Company Line Document Entrance PointOfInterest Shape]
        enumerize :uniqueness_scope, in: %w[workgroup workbench provider]

        validates :target_model, :target_code_space_id, presence: true

        def target_code_space
          @target_code_space ||= workgroup.code_spaces.find_by_id(target_code_space_id)
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
            code_space: target_code_space.short_name,
            name: duplicate.name, code_value: duplicate.code_value
          },
          criticity: criticity, message_key: :code_uniqueness,
          source_id: duplicate.source_id, source_type: duplicate.source_type
        )
      end

      def analysis
        Analysis.for(uniqueness_scope).new(context, target_model, target_code_space)
      end

      class Analysis
        def self.for(uniqueness_scope)
          const_get(uniqueness_scope.classify)
        end

        class Base
          def initialize(context, target_model, target_code_space)
            @context = context
            @target_model = target_model
            @target_code_space = target_code_space
          end

          attr_accessor :target_model, :context, :target_code_space

          PREFIX_PROVIDERS = {
            stop_area: 'stop_area',
            company: 'line',
            line: 'line',
            document: 'document',
            entrance: 'stop_area',
            point_of_interest: 'shape',
            shape: 'shape'
          }.with_indifferent_access

          def duplicates
            PostgreSQLCursor::Cursor.new(query).map do |attributes|
              Duplicate.new attributes.merge source_type: source_type
            end
          end

          def model_singular
            @model_singular ||= target_model.underscore
          end

          def source_type
            @source_type ||= begin
              source_type = (target_model.constantize rescue "Chouette::#{target_model}".constantize).to_s rescue nil
              source_type || 'PointOfInterest::Base'
            end
          end

          def model_collection
            @model_collection ||= model_singular.pluralize
          end

          def model_table_name
            @model_table_name ||= models.table_name
          end

          def models
            context.send(model_collection)
          end

          def provider_id
            "#{model_collection}.#{PREFIX_PROVIDERS[model_singular]}_provider_id"
          end

          def providers
            "#{PREFIX_PROVIDERS[model_singular]}_providers"
          end

          def query
            <<~SQL
              SELECT * FROM (
                SELECT #{model_table_name}.*, #{duplicates_count} AS duplicates_count
                FROM #{model_table_name}
                #{inner_join}
                WHERE (codes.resource_type = '#{source_type}')
                  AND (codes.code_space_id = #{target_code_space.id})
                  AND (#{model_table_name}.id IN (#{models.select(:id).to_sql}))
              ) AS with_duplicates_count
              WHERE duplicates_count > 1
            SQL
          end

          class Duplicate
            def initialize(attributes)
              attributes.each { |k, v| send "#{k}=", v if respond_to?(k) }
            end

            attr_accessor :name, :source_type, :code_value, :id

            alias source_id id
          end
        end

        class Provider < Base
          def duplicates_count
            <<~SQL
              count(#{model_table_name}.id) OVER(PARTITION BY #{provider_id}, codes.value)
            SQL
          end

          def inner_join
            <<~SQL
              INNER JOIN public.codes ON codes.resource_id = #{model_table_name}.id
            SQL
          end
        end

        class Workbench < Base
          def duplicates_count
            <<~SQL
              count(#{model_table_name}.id) OVER(PARTITION BY workbenches.id, codes.value)
            SQL
          end

          def inner_join
            <<~SQL
              INNER JOIN public.#{providers} ON #{providers}.id = #{provider_id}
              INNER JOIN public.workbenches ON workbenches.id = #{providers}.workbench_id
              INNER JOIN public.codes ON codes.resource_id = #{model_table_name}.id
            SQL
          end
        end

        class Workgroup < Base
          def duplicates_count
            <<~SQL
              count(#{model_table_name}.id) OVER(PARTITION BY workgroups.id, codes.value)
            SQL
          end

          def inner_join
            <<~SQL
              INNER JOIN public.#{providers} ON #{providers}.id = #{provider_id}
              INNER JOIN public.workbenches ON workbenches.id = #{providers}.workbench_id
              INNER JOIN public.workgroups ON workgroups.id = workbenches.workgroup_id
              INNER JOIN public.codes ON codes.resource_id = #{model_table_name}.id
            SQL
          end
        end
      end
    end
  end
end