module CustomFieldsSupport
  extend ActiveSupport::Concern

  THREAD_VARIABLE_NAME = "current_workgroup"
  def self.within_workgroup workgroup
    if current_workgroup
      if current_workgroup != workgroup
        raise "Two different current workgroups: current:#{current_workgroup.id} wanted:#{workgroup.id}"
      end
      Rails.logger.info "within_workgroup used twice"
      return yield
    end

    Rails.logger.debug "Set current workgroup: #{workgroup&.id}"

    value = nil
    begin
      Thread.current.thread_variable_set(THREAD_VARIABLE_NAME, workgroup)
      value = yield
    ensure
      Thread.current.thread_variable_set(THREAD_VARIABLE_NAME, nil)
    end

    Rails.logger.debug "Reset current workgroup"

    value
  end

  def self.current_workgroup
    Thread.current.thread_variable_get(THREAD_VARIABLE_NAME)
  end

  included do
    validate :custom_fields_values_are_valid
    after_initialize :initialize_custom_fields
    attr_accessor :skip_custom_fields_initialization

    def self.reset_custom_fields
      @_custom_fields = nil
    end

    def self._get_custom_fields(workgroup)
      fields = CustomField.where(resource_type: self.name.split("::").last)
      fields = fields.where(workgroup_id: workgroup.id)
      fields
    end

    def self.custom_fields workgroup
      return CustomField.none unless workgroup
      @_custom_fields ||= {}
      unless @_custom_fields.has_key?(workgroup.id) && @_custom_fields[workgroup.id].first == workgroup.updated_at
        @_custom_fields[workgroup.id] = [workgroup.updated_at, _get_custom_fields(workgroup)]
      end
      @_custom_fields[workgroup.id].last
    end

    def self.custom_fields_definitions workgroup
      Hash[*custom_fields(workgroup).map{|cf| [cf.code, cf]}.flatten]
    end

    def self.within_workgroup workgroup, &block
      ActiveSupport::Deprecation.warn('Use CustomFieldsSupport.within_workgroup')
      CustomFieldsSupport.within_workgroup workgroup, &block
    end

    def self.current_workgroup
      CustomFieldsSupport.current_workgroup
    end

    def method_missing method_name, *args
      if !@custom_fields_initialized && (method_name =~ /custom_field_*/ || method_name =~ /remove_custom_field_*/) && method_name.to_sym != :custom_field_values
        initialize_custom_fields
        send method_name, *args
      else
        super method_name, *args
      end
    end

    def custom_fields deprecated_workgroup=nil
      _workgroup = deprecated_workgroup || self.workgroup
      CustomField::Collection.new self, _workgroup
    end

    def custom_fields_checksum
      custom_fields.values.sort_by(&:code).map(&:checksum).compact
    end

    def custom_field_values= vals
      if custom_fields_initialized?
        out = {}
        custom_fields.each do |code, field|
          out[code] = field.preprocess_value_for_assignment(vals.symbolize_keys[code.to_sym])
        end
        @custom_fields_values_initialized = true
      else
        @raw_custom_fields_values = vals
        out = vals
      end
      write_attribute :custom_field_values, out
    end

    def custom_fields_initialized?
      !!@custom_fields_initialized
    end

    def custom_fields_values_initialized?
      !!@custom_fields_values_initialized
    end

    def initialize_custom_fields
      return if skip_custom_fields_initialization
      return if custom_fields_initialized?
      return unless self.attributes.has_key?("custom_field_values")
      return unless self.workgroup.present?

      self.custom_field_values ||= {}
      custom_fields.values.each &:initialize_custom_field
      custom_fields.each do |k, v|
        custom_field_values[k] ||= v.default_value
      end
      @custom_fields_initialized = true
      self.custom_field_values = (@raw_custom_fields_values || self.custom_field_values) unless custom_fields_values_initialized?
    end

    def custom_field_value key
      (custom_field_values&.stringify_keys || {})[key.to_s]
    end

    private
    def custom_fields_values_are_valid
      return if skip_custom_fields_initialization

      custom_fields.values.all?{|cf| cf.valid?}
    end
  end
end
