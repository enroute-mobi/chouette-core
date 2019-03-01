class WorkbenchImportService
  module ObjectStateUpdater

    def resource entry
      @_resources ||= {}
      @_resources[entry.name] ||= workbench_import.resources.find_or_create_by(name: entry.name, resource_type: "referential")
    end

    def update_object_state entry, count
      workbench_import.update( total_steps: count )
      update_spurious entry
      update_foreign_lines entry
      update_missing_calendar entry
      update_wrong_calendar entry
    end

    private

    def update_foreign_lines entry
      update_with_error(
        entry,
        'foreign_lines_in_referential',
        {
          'source_filename' => workbench_import.file.file.file,
          'foreign_lines'   => entry.foreign_lines.join(', ')
        }
      ) do
        entry.foreign_lines.present?
      end
    end

    def update_spurious entry
      update_with_error(
        entry,
        'inconsistent_zip_file',
        {
          'source_filename' => workbench_import.file.file.file,
          'spurious_dirs'   => entry.spurious.join(', ')
        }
      ) do
        entry.spurious.present?
      end
    end

    def update_missing_calendar entry
      update_with_error entry, 'missing_calendar_in_zip_file', 'source_filename' => entry.name do
        entry.missing_calendar
      end
    end

    def update_wrong_calendar entry
      update_with_error entry, 'wrong_calendar_in_zip_file', 'source_filename' => entry.name do
        entry.wrong_calendar
      end
    end

    def update_with_error(entry, message_key, message_attributes)
      return unless yield entry
      resource(entry).messages.create(
        criticity: :error,
        message_key: message_key,
        message_attributes: message_attributes)
      resource(entry).update status: :ERROR
    end
  end
end
