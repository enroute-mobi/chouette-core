module PublicationSetups
  class ExportOptionsValidator < ActiveModel::Validator
    def validate(record)
      export = record.export

      error_keys = %i[type] + export.class.options.keys

      export.validate

      export.errors.each do |key, _message|
        export.errors.delete(key) unless error_keys.include?(key)
      end

      record.errors.add(:export_options, :invalid) if export.errors.any?
    end
  end
end