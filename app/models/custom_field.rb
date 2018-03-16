class CustomField < ActiveRecord::Base

  extend Enumerize
  belongs_to :workgroup
  enumerize :field_type, in: %i{list integer string attachment}

  validates :name, uniqueness: {scope: [:resource_type, :workgroup_id]}
  validates :code, uniqueness: {scope: [:resource_type, :workgroup_id], case_sensitive: false}

  scope :for_workgroup, ->(workgroup){ where workgroup_id: workgroup.id }

  class Collection < HashWithIndifferentAccess
    def initialize object
      vals = object.class.custom_fields.map do |v|
        [v.code, CustomField::Instance.new(object, v, object.custom_field_value(v.code))]
      end
      super Hash[*vals.flatten]
    end

    def to_hash
      HashWithIndifferentAccess[*self.map{|k, v| [k, v.to_hash]}.flatten(1)]
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

      delegate :code, :name, :field_type, to: :@custom_field

      def default_value
        options["default"]
      end

      def options
        @custom_field.options || {}
      end

      def validate
        @valid = true
      end

      def valid?
        validate unless @validated
        @valid
      end

      def value
        @raw_value
      end

      def input form_helper
        @input ||= begin
          klass_name = field_type && "CustomField::Instance::#{field_type.classify}::Input"
          klass = klass_name.safe_constantize || CustomField::Instance::Base::Input
          klass.new self, form_helper
        end
      end

      def errors_key
        "custom_fields.#{code}"
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
        val
      end

      def render_partial
        ActionView::Base.new(Rails.configuration.paths["app/views"].first).render(
          :partial => "shared/custom_fields/#{field_type}",
          :locals => { field: self}
        )
      end

      class Input
        def initialize instance, form_helper
          @instance = instance
          @form_helper = form_helper
        end

        def custom_field
          @instance.custom_field
        end

        delegate :custom_field, :value, :options, to: :@instance
        delegate :code, :name, :field_type, to: :custom_field

        def to_s
          out = form_input
          out.html_safe
        end

        protected

        def form_input_id
          "custom_field_#{code}"
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
        @raw_value&.to_i
      end

      def validate
        @valid = true
        return if @raw_value.is_a?(Fixnum) || @raw_value.is_a?(Float)
        unless @raw_value.to_s =~ /\A\d*\Z/
          @owner.errors.add errors_key, "'#{@raw_value}' is not a valid integer"
          @valid = false
        end
      end
    end

    class List < Integer
      def validate
        super
        return unless value.present?
        unless value >= 0 && value < options["list_values"].size
          @owner.errors.add errors_key, "'#{@raw_value}' is not a valid value"
          @valid = false
        end
      end

      def display_value
        options["list_values"][value.to_s]
      end

      class Input < Base::Input
        def form_input_options
          super.update({
            selected: value,
            collection: options["list_values"].map(&:reverse)
          })
        end
      end
    end

    class Attachment < Base
      def initialize_custom_field
        custom_field_code = self.code
        _attr_name = attr_name
        _uploader_name = uploader_name
        owner.send :define_singleton_method, "read_uploader" do |attr|
          if attr.to_s == _attr_name
            custom_field_values[custom_field_code]
          else
            read_attribute attr
          end
        end

        owner.send :define_singleton_method, "write_uploader" do |attr, val|
          if attr.to_s == _attr_name
            custom_field_values[custom_field_code] = val
          else
            write_attribute attr, val
          end
        end

        owner.send :define_singleton_method, "#{_attr_name}_will_change!" do
          custom_field_values_will_change!
        end

        _extension_whitelist = options["extension_whitelist"]

        owner.send :define_singleton_method, "#{_uploader_name}_extension_whitelist" do
          _extension_whitelist
        end

        unless owner.class.uploaders.has_key? _uploader_name.to_sym
          owner.class.mount_uploader _uploader_name, CustomFieldAttachmentUploader, mount_on: "custom_field_#{code}_raw_value"
        end
      end

      def preprocess_value_for_assignment val
        if val.present?
          owner.send "#{uploader_name}=", val
        else
          @raw_value
        end
      end

      def value
        owner.send "custom_field_#{code}"
      end

      def raw_value
        @raw_value
      end

      def attr_name
        "custom_field_#{code}_raw_value"
      end

      def uploader_name
        "custom_field_#{code}"
      end

      def display_value
        render_partial
      end

      class Input < Base::Input
        def form_input_options
          super.update({
            as: :file,
            wrapper: :horizontal_file_input
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
