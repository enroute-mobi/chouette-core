class Destination::SFTP < ::Destination
  require 'net/sftp'

  option :host
  option :port, default_value: 22
  option :directory
  option :username

  validates :host, presence: true
  validates :directory, presence: true
  validates :username, presence: true

  @secret_file_required = true

  def transmit_export_file(_publication, _report, export)
    Net::SFTP.start(host, username, port: port, keys: [secret_file.path], auth_methods: %w[publickey]) do |sftp|
      file_name = File.basename(export.file.path)
      remote_file_path = "#{directory}/#{file_name}"
      sftp.upload!(export.file.path, remote_file_path)
    end
  end
end
