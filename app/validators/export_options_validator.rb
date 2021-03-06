class ExportOptionsValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    export = record.is_a?(Export::Base) ? record : record.export

    extra_attributes = options.fetch(:extra_attributes, [])
    options_keys = export.class.options.keys

    keys = extra_attributes + options_keys

    export.class.validators_on(*keys).each do |v|
      _if = v.options.fetch(:if, ->(e) { true }) #FIXME check if there is a better way to do it

      v.validate(export) if _if.call(export)
    end

    export.options.each do |k, _v|
      unless keys.include?(k.to_sym)
        export.errors.add(:options, :not_supported, name: k)
      end
    end

    record.errors.add(attribute, :invalid) unless (export.errors.keys & keys).empty?
  end
end