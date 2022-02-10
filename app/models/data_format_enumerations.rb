# DEPRECATED
module DataFormatEnumerations
  extend Enumerize
  extend ActiveModel::Naming

  enumerize :data_format, in: %w[neptune netex gtfs], default: "netex"
end
