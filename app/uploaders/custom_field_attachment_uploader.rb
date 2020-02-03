class CustomFieldAttachmentUploader < CarrierWave::Uploader::Base
  include CarrierWave::RMagick

  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  def extension_whitelist
    model.send "#{mounted_as}_extension_whitelist"
  end

  process :dynamic_versions

  def method_missing mid, *args
    unless @dynamic_versions_loaded
      dynamic_versions
      @versions = nil
      cache!
    end
    send mid, *args
  end

  def dynamic_versions
    custom_field = model.custom_fields[mounted_as.to_s.gsub('custom_field_', '').to_sym]
    _versions = custom_field.options["versions"] || {}
    _mounted_as = mounted_as
    _versions.each do |name, size|
      size = size.split('x')
      self.class.version name, if: ->(uploader, picture){ uploader.mounted_as == _mounted_as} do |obj|
        process :resize_to_fit => size
      end
    end
    @dynamic_versions_loaded = true
  end
end
