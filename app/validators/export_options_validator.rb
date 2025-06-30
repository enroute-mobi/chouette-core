# frozen_string_literal: true

class ExportOptionsValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, _value) # rubocop:disable Metrics/MethodLength,Metrics/AbcSize
    export = record.is_a?(Export::Base) ? record : record.export

    extra_attributes = options.fetch(:extra_attributes, [])
    keys = extra_attributes + export.class.options.keys

    export.class.validators_on(*keys).each do |v|
      _if = v.options.fetch(:if, ->(e) { true }) #FIXME check if there is a better way to do it

      v.validate(export) if _if.call(export)
    end

    export.options.each_key do |k|
      next if keys.include?(k.to_sym)

      export.errors.add(:options, :not_supported, name: k)
    end

    record.errors.add(attribute, :invalid) unless (export.errors.attribute_names & keys).empty?
  end
end
