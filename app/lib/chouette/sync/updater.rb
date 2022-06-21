module Chouette
  module Sync
    class Updater

      def initialize(options = {})
        options.reverse_merge!(update_batch_size: 1000)
        options.each { |k,v| send "#{k}=", v }
      end

      attr_accessor :source, :target, :update_batch_size, :default_provider
      attr_accessor :resource_type, :resource_id_attribute, :resource_decorator
      attr_accessor :model_type, :model_id_attribute, :code_space
      include Event::HandlerSupport

      delegate :workgroup, to: :target

      def resources
        @resources ||= source.send(resource_type.to_s.pluralize)
      end

      def resources_in_batches
        resources.each_slice(update_batch_size) do |resources_batch|
          yield Batch.new(resources_batch, updater: self)
        end
      end

      def transaction(&block)
        CustomFieldsSupport.within_workgroup(workgroup) do
          target.class.transaction(&block)
        end
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

      # Collection to be modified in the target: lines, stop_areas, etc
      def scope
        @scope ||= target.send(model_type.to_s.pluralize)
      end

      def models
        Models.new scope, updater: self
      end

      def provider
        @provider ||= Provider.new target, default_provider
      end

      class Provider
        def initialize(target, default_provider)
          @target = target
          @default_provider = default_provider
        end
        attr_accessor :target, :default_provider

        def scope
          @scope ||= target.send(collection)
        end

        def collection
          @collection ||= singular_provider.pluralize
        end

        def singular_provider_id
          "#{singular_provider}_id"
        end

        def singular_provider
          @singular_provider ||= singular.gsub('_referential', '_provider')
        end

        def target_is_provider?
          singular.end_with? '_provider'
        end

        def singular
          @singular ||= target.model_name.singular
        end
      end

      class Models

        attr_accessor :scope, :updater

        def initialize(scope, updater: nil)
          @scope = scope
          @updater = updater
        end

        delegate :model_id_attribute, :event_handler, :workgroup, :code_space, :target, :provider, to: :updater

        def with_resource_ids(resource_ids)
          scope.where(model_id_attribute => resource_ids).find_each do |model|
            resource_id = model.send model_id_attribute
            yield model, resource_id
          end
        end

        def with_codes(resource_ids)
          scope.by_code(code_space, resource_ids).find_each do |model|
            value = model.codes&.first&.value
            yield model, value
          end
        end

        IGNORED_ATTRIBUTE_VALUES = [nil, "", []].freeze

        def prepare_attributes(resource)
          attributes = resource.model_attributes

          # To avoid problem if resource returns by mistake an id attribute
          if attributes.delete(:id)
            Rails.logger.warn "Can't update primary key with resource: #{resource.class}"
          end

          if model_id_attribute == :codes
            attributes[:codes_attributes] = [{
              value: resource.id,
              code_space: code_space
            }]
          else
            attributes[model_id_attribute] = resource.id
          end

          # Could be conditionnal
          attributes.delete_if do |_, value|
            IGNORED_ATTRIBUTE_VALUES.include? value
          end

          attributes
        end

        def create(resource)
          attributes = prepare_attributes(resource)
          model = scope.build attributes

          event = Event.new :create, model: model, resource: ResourceDecorator.undecorate(resource)

          update_providers model, resource, event
          update_codes model, resource, event
          update_custom_fields model, resource, event

          model.save

          event_handler.event event
        end

        def update(model, resource)
          attributes = prepare_attributes(resource)
          Rails.logger.debug { "Update #{model.inspect} with #{attributes.inspect}" }

          model.attributes = attributes.except(:codes_attributes)

          event = Event.new :update, model: model, resource: ResourceDecorator.undecorate(resource)

          update_providers model, resource, event
          update_codes model, resource, event
          update_custom_fields model, resource, event

          model.save
          event_handler.event event
        end

        def find_code_space(short_name)
          workgroup.code_spaces.find_by short_name: short_name
        end

        def update_codes(model, resource, event)
          return unless model.respond_to?(:codes) && resource.respond_to?(:codes_attributes)

          resource.codes_attributes.each do |code_attributes|
            short_name = code_attributes[:short_name]
            value = code_attributes[:value]

            if (code_space = find_code_space(short_name))
              model.codes.find_or_initialize_by code_space: code_space, value: value
            else
              (event.errors[:codes] ||= []) << { error: :invalid_code_space, value: short_name }
            end
          end
        end

        def update_providers(model, resource, event)
          return if provider.target_is_provider?

          update_provider = UpdateProvider.new(target, resource, code_space, provider)
          if update_provider.not_found?
            (event.errors[:provider] ||= []) << {
              error: :provider_not_found,
              value: resource.data_source_ref
            }
          else
            model.send("#{update_provider.singular_provider_id}=", update_provider.id)
          end
        end

        class UpdateProvider
          def initialize(target, resource, code_space, provider)
            @target = target
            @resource = resource
            @code_space = code_space
            @provider = provider
          end
          attr_accessor :target, :resource, :code_space, :provider

          delegate :singular_provider_id, :scope, :default_provider, to: :provider

          def data_source_ref
            @data_source_ref ||= resource.data_source_ref
          end

          def not_found?
            find_provider.blank? && data_source_ref.present?
          end

          def id
            @id ||= default_provider&.id unless data_source_ref.present?
            @id ||= find_provider&.id
          end

          def find_provider
            @find_provider ||= find_provider_by_codes || find_provider_by_columns
          end

          def find_provider_by_codes
            if scope.respond_to? :by_code
              scope.by_code(code_space, data_source_ref).first
            end
          end

          def find_provider_by_columns
            if scope.column_names.include? 'objectid'
              if (p = scope.find_by(objectid: data_source_ref)).present?
                return p
              end
            end

            nil
          end
        end

        def custom_field(code)
          workgroup.custom_fields.find_by code: code
        end

        def update_custom_fields(model, resource, event)
          return unless resource.respond_to?(:custom_fields_attributes)

          resource.custom_fields_attributes.each do |custom_field_attributes|
            code = custom_field_attributes[:code]
            value = custom_field_attributes[:value]

            if (custom_field = custom_field(code))
              custom_field_instance = CustomField::Instance.new model, custom_field, value
              # The custom field validation adds error in model
              if custom_field_instance.valid?
                # model.initialize_custom_fields
                model.custom_field_values = model.custom_field_values.merge(code => value)
              end
            else
              (event.errors[:custom_fields] ||= []) << { error: :invalid_custom_field, value: code }
            end
          end

        end
      end

      class Batch

        attr_reader :resources, :updater

        def initialize(resources, updater: nil)
          @resources = resources
          @updater = updater
        end

        delegate :resource_id_attribute, :model_id_attribute, :models, :resource_decorator, :code_space, to: :updater

        def decorate(resource)
          resource_decorator.new resource, batch: self
        end

        def resource_ids
          resources_by_id.keys
        end

        def resources_by_id
          @resources_by_id ||=  Hash[resources.map { |r| [ r.send(resource_id_attribute).to_s, r ] }]
        end

        def resource_by_id(resource_id)
          resources_by_id.fetch resource_id
        end

        def with_model_ids
          if model_id_attribute == :codes
            "with_codes"
          else
            "with_resource_ids"
          end
        end

        def existing_models
          models.send(with_model_ids, resource_ids) do |model, resource_id|
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

        def new_resources
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

        # Basic resolver implementation

        def resolve(reference_type, resource_ids)
          if resource_ids.is_a? Array
            resolve_multiple reference_type, resource_ids
          else
            resolve_one reference_type, resource_ids
          end
        end

        def resolve_one(reference_type, resource_id)
          resolve_multiple(reference_type, [resource_id]).first
        end

        def resolve_multiple(reference_type, resource_ids)
          resource_ids.compact!

          Identifier.new(reference_type, resource_ids, model_id_attribute, code_space, updater).identifiers
        end

        class Identifier
          def initialize(reference_type, resource_ids, model_id_attribute, code_space, updater)
            @reference_type = reference_type
            @resource_ids = resource_ids
            @model_id_attribute = model_id_attribute
            @code_space = code_space
            @updater = updater
          end
          attr_accessor :reference_type, :resource_ids, :model_id_attribute, :code_space, :updater

          def identifiers
            return [] if resource_ids.empty? || !model_ref

            ids = if support_model_id_attribute?
              model_ref.where(model_id_attribute => resource_ids).pluck(:id)
            elsif support_codes?
              model_ref.by_code(code_space, resource_ids).pluck(:id)
            end

            unless ids.present?
              key_field = model_id_attribute_from_reference_type(reference_type)
              ids = model_ref.where(key_field => resource_ids).pluck(:id)
            end

            ids
          end

          private

          def model_ref
            collection = reference_type.to_s.pluralize
            if updater.target.respond_to? collection
              updater.target.send(collection)
            end
          end

          def support_codes?
            model_ref.reflect_on_all_associations(:has_many).map(&:name).include?(:codes)
          end

          def support_model_id_attribute?
            model_ref.column_names.include? model_id_attribute.to_s
          end

          def model_id_attribute_from_reference_type(reference_type)
            begin
            "Chouette::Sync::#{reference_type.to_s.classify}::Netex".
              constantize.default_model_id_attribute
            rescue
              ::Chouette::Sync::Base.default_model_id_attribute
            end
          end
        end
      end

      class ResourceDecorator < SimpleDelegator

        attr_reader :batch

        # Batch is optionnal .. for tests
        def initialize(resource, batch: nil)
          super resource
          @resource = resource
          @batch = batch
        end

        def to_resource
          @resource
        end

        delegate :resolve, :updater, to: :batch

        def self.undecorate(resource_or_decorator)
          if resource_or_decorator.respond_to?(:to_resource)
            resource_or_decorator.to_resource
          else
            resource_or_decorator
          end
        end

      end

    end
  end
end
