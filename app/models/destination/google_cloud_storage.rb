# frozen_string_literal: true

require 'google/cloud/storage'

class Destination
  class GoogleCloudStorage < ::Destination
    option :project
    option :bucket

    validates :project, presence: true
    validates :bucket, presence: true

    @secret_file_required = true

    def transmit_export_file(_publication, _report, export)
      storage = Google::Cloud::Storage.new(
        project_id: project,
        credentials: secret_file.path
      )
      bucket = storage.bucket self.bucket, skip_lookup: true
      bucket.create_file(export.file.path, File.basename(export.file.path))
    end
  end
end
