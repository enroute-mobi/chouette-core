class CustomField < ApplicationModel

  extend Enumerize
  belongs_to :workgroup
  belongs_to :custom_field_group, optional: true

  enumerize :field_type, in: %i[list integer float string]

  validates :name, uniqueness: {scope: [:resource_type, :workgroup_id]}
  validates :code, uniqueness: {scope: [:resource_type, :workgroup_id], case_sensitive: false}, presence: true
  validates :workgroup, :resource_type, :field_type, presence: true

  acts_as_list scope: 'custom_field_group_id #{custom_field_group_id ? "= #{custom_field_group_id}" : "IS NULL"} AND workgroup_id #{workgroup_id ? "= #{workgroup_id}" : "IS NULL"}'

  after_save do
    resource_class&.reset_custom_fields
  end

  def resource_class
    if resource_type
      resource_class = resource_type.safe_constantize
      resource_class ||= "Chouette::#{resource_type}".constantize
      resource_class
    end
  end

  class Collection < HashWithIndifferentAccess
    def initialize(object, workgroup=nil)
      vals = object.class.custom_fields(workgroup).map do |v|
        [v.code, CustomField::Instance.new(object, v, object.custom_field_value(v.code))]
      end
      super Hash[*vals.flatten]
    end

    def self.new(object, workgroup=nil)
      return object if object.is_a?(Collection)
      super
    end

    def to_hash
      HashWithIndifferentAccess[*self.map{|k, v| [k, v.to_hash]}.flatten(1)]
    end

    def by_group(&block)
      values.group_by(&:custom_field_group).to_a.sort_by { |group, _| group&.position || 0 }.each do |group, custom_fields|
        yield group, custom_fields
      end
    end

    def for_section(section)
      select do |_code, field|
        field.options["section"] == section
      end
    end

    def without_section
      select do |_code, field|
        field.options["section"].blank?
      end
    end

    def except_for_sections(sections)
      reject do |_code, field|
        field.options["section"].blank? || sections.include?(field.options["section"])
      end
    end
  end

  class Instance
    def self.new owner, custom_field, value
      field_type = custom_field.field_type
      klass_name = field_type && "CustomField::Instance::#{field_type.classify}"
      klass = klass_name.safe_constantize || CustomField::Instance::Base
      klass.new owner, custom_field, value
    end

    class Base
      def initialize owner, custom_field, value
        @custom_field = custom_field
        @raw_value = value
        @owner = owner
        @errors = []
        @validated = false
        @valid = false
      end

      attr_accessor :owner, :custom_field

      delegate :code, :name, :field_type, :custom_field_group, :position, to: :custom_field

      def default_value
        options["default"]
      end

      def options
        @custom_field.options&.stringify_keys || {}
      end

      def validate
        @valid = true
      end

      def valid?
        validate unless @validated
        @valid
      end

      def required?
        !!options["required"]
      end

      def value
        @raw_value
      end

      def value=(value)
        @raw_value = value
      end

      def checksum
        val = @raw_value
        return nil if !val.present? && !!options["ignore_empty_value_in_checksums"]
        "#{val}"
      end

      def input form_helper
        @input ||= begin
          klass_name = field_type && "CustomField::Instance::#{field_type.classify}::Input"
          klass = klass_name.safe_constantize || CustomField::Instance::Base::Input
          klass.new self, form_helper
        end
      end

      def errors_key
        # this must match the ID used in the inputs
        "custom_field_#{code}"
      end

      def to_hash
        HashWithIndifferentAccess[*%w(code name field_type options value).map{|k| [k, send(k)]}.flatten(1)]
      end

      def display_value
        value
      end

      def initialize_custom_field
      end

      def preprocess_value_for_assignment val
        val || default_value
      end

      class Input
        def initialize instance, form_helper
          @instance = instance
          @form_helper = form_helper
        end

        def custom_field
          @instance.custom_field
        end

        delegate :custom_field, :value, :options, :required?, to: :@instance
        delegate :code, :name, :field_type, to: :custom_field

        def to_s
          out = form_input
          out.html_safe
        end

        protected

        def form_input_id
          "custom_field_#{code}".to_sym
        end

        def form_input_name
          "#{@form_helper.object_name}[custom_field_values][#{code}]"
        end

        def form_input_options
          {
            input_html: {value: value, name: form_input_name},
            label: name
          }
        end

        def form_input
          @form_helper.input form_input_id, form_input_options
        end
      end
    end

    class Integer < Base
      def value
        @raw_value.present? ? @raw_value.to_i : nil
      end

      def validate
        @valid = true
        return if @raw_value.is_a?(Integer)
        unless @raw_value.to_s =~ /\A-?\d*\Z/
          @owner.errors.add errors_key, "'#{@raw_value}' is not a valid integer"
          @valid = false
        end
      end

      class Input < Base::Input
        def form_input_options
          super.update({
            as: :integer
          })
        end
      end
    end

    class Float < Integer
      def value
        @raw_value.present? ? @raw_value.to_f : nil
      end

      def validate
        @valid = true
        return if @raw_value.is_a?(Integer) || @raw_value.is_a?(Float)
        unless @raw_value.to_s =~ /\A-?\d*(\.\d+)?\Z/
          @owner.errors.add errors_key, "'#{@raw_value}' is not a valid float"
          @valid = false
        end
      end

      class Input < Base::Input
        def form_input_options
          super.update({
            as: :float
          })
        end
      end
    end

    class List < Base
      def collection_is_a_hash?
        options["list_values"].is_a?(Hash)
      end

      def validate
        return unless value.present?
        @valid = true

        if collection_is_a_hash?
          unless options["list_values"].keys.map(&:to_s).include?(key)
            @owner.errors.add errors_key, "'#{@raw_value}' is not a valid value"
            @valid = false
          end
        else
          unless index && index >= 0 && index < options["list_values"].size
            @owner.errors.add errors_key, "'#{@raw_value}' is not a valid value"
            @valid = false
          end
        end
      end

      def key
        return unless value.present?
        return unless collection_is_a_hash?

        value.to_s
      end

      def index
        return unless value.present?
        return if collection_is_a_hash?
        return if value.is_a?(::String) && !value.match?(/^[0-9]+$/)

        @index ||= value.to_i
      end

      def key_or_index
        key || index
      end

      def display_value
        options["list_values"][key_or_index] if key_or_index
      end

      class Input < Base::Input
        def form_input_options
          collection = options["list_values"]
          collection = collection.each_with_index.to_a if collection.is_a?(Array)
          collection = collection.map(&:reverse) if collection.is_a?(Hash)
          collection = [["", ""]] + collection unless required?
          super.update({
            selected: value,
            collection: collection
          })
        end
      end
    end

    class String < Base
      def value
        "#{@raw_value}"
      end
    end
  end
end
