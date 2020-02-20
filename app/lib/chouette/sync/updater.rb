module Chouette
  module Sync
    class Updater

      def initialize(options = {})
        options.reverse_merge!(update_batch_size: 1000)
        options.each { |k,v| send "#{k}=", v }
      end

      attr_accessor :source, :target, :update_batch_size
      attr_accessor :resource_type, :resource_id_attribute, :resource_decorator
      attr_accessor :model_type, :model_id_attribute

      def resources
        @resources ||= source.send("#{resource_type}s")
      end

      def resources_in_batches(&block)
        resources.each_slice(update_batch_size) do |resources_batch|
          yield Batch.new(resources_batch, updater: self)
        end
      end

      def transaction(&block)
        target.class.transaction(&block)
      end

      def update_or_create
        resources_in_batches do |batch|
          transaction do
            batch.update_all
            batch.create_all
          end

          processed_identifiers.concat batch.resource_ids
        end
      end

      def processed_identifiers
        @processed_identifiers ||= []
      end

      def counts
        @counts ||= Hash.new { |h,k| h[k] = 0 }
      end

      def count(type)
        counts[type]
      end

      def increment_count(type)
        counts[type] += 1
      end

      def report_invalid_model(model, resource)
        puts [model, resource].inspect
      end

      # Collection to be modified in the target: lines, stop_areas, etc
      def scope
        @scope ||= target.send("#{model_type}s")
      end

      def models
        Models.new scope, updater: self
      end

      class Models

        attr_accessor :scope, :updater

        def initialize(scope, updater: nil)
          @scope = scope
          @updater = updater
        end

        delegate :model_id_attribute, :increment_count, :report_invalid_model, to: :updater

        def with_resource_ids(resource_ids, &block)
          scope.where(model_id_attribute => resource_ids).find_each do |model|
            resource_id = model.send model_id_attribute
            yield model, resource_id
          end
        end

        def prepare_attributes(resource)
          attributes = resource.model_attributes

          # To avoid problem if resource returns by mistake an id attribute
          if attributes.delete(:id)
            Rails.logger.warn "Can't update primary key with resource: #{resource.class}"
          end

          attributes[model_id_attribute] = resource.id

          # Could be conditionnal
          attributes.delete_if do |attribute, value|
            not value.present?
          end

          attributes
        end

        def create(resource)
          attributes = prepare_attributes(resource)
          model = scope.create(attributes)
          if model.persisted?
            increment_count :create
          else
            report_invalid_model model, resource
          end
        end

        def update(model, resource)
          attributes = prepare_attributes(resource)
          if model.update(attributes)
            increment_count :update
          else
            report_invalid_model model, resource
          end
        end

      end

      class Batch

        attr_reader :resources, :updater

        def initialize(resources, updater: nil)
          @resources = resources
          @updater = updater
        end

        delegate :resource_id_attribute, :models, :resource_decorator, to: :updater

        def decorate(resource)
          resource_decorator.new resource, batch: self
        end

        def resource_ids
          resources_by_id.keys
        end

        def resources_by_id
          @resources_by_id ||= Hash[resources.map { |r| [ r.send(resource_id_attribute).to_s, r ] }]
        end

        def resource_by_id(resource_id)
          resources_by_id.fetch resource_id
        end

        def existing_models(&block)
          models.with_resource_ids(resource_ids) do |model, resource_id|
            resource = resource_by_id(resource_id)
            yield model, decorate(resource)

            resource_exists! resource_id
          end
        end

        def new_resources_by_id
          @new_resources ||= resources_by_id.dup
        end

        def resource_exists!(resource_id)
          new_resources_by_id.delete resource_id
        end

        def new_resources(&block)
          new_resources_by_id.values.each do |resource|
            yield decorate(resource)
          end
        end

        def update_all
          existing_models do |model, decorated_resource|
            models.update model, decorated_resource
          end
        end

        def create_all
          new_resources do |decorated_resource|
            models.create decorated_resource
          end
        end

        def resolve(reference_type, resource_id)
          # use a cache ? with limited size ?
          # like https://github.com/SamSaffron/lru_redux/blob/master/lib/lru_redux/cache.rb
          updater.target.send("#{reference_type}s").find_by(resource_id_attribute => resource_id)
        end

      end

      class ResourceDecorator < SimpleDelegator

        attr_reader :batch

        # Batch is optionnal .. for tests
        def initialize(resource, batch: nil)
          super resource
          @batch = batch
        end

        delegate :resolve, to: :batch

      end

    end
  end
end
