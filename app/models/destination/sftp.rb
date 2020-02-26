if ::Destination.enabled?("sftp")
  class Destination::SFTP < ::Destination
    require 'net/sftp'

    option :host, required: true
    option :port, default_value: 22
    option :directory, required: true
    option :username, required: true

    @secret_file_required = true

    def do_transmit(publication, report)
      Net::SFTP.start(host, username, port: port, keys: [local_secret_file.path], auth_methods: %w[publickey]) do |sftp|
        publication.exports.each do |export|
          next unless export[:file].present?

          local_file = local_temp_file(export.file)
          file_name = File.basename export.file.path
          remote_file_path = "#{directory}/#{file_name}"
          sftp.upload!(local_file.path, remote_file_path)
        end
      end
    end
  end
end
