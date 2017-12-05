module ObjectidFormatterSupport
  extend ActiveSupport::Concern

  class << self
    def legal_formats
      %w(netex stif_netex stif_reflex stif_codifligne)
    end

    def default_format; 'netex' end
  end

  included do
    extend Enumerize
    enumerize :objectid_format, in: ObjectidFormatterSupport.legal_formats, default: ObjectidFormatterSupport.default_format
    validates_presence_of :objectid_format
    
    def objectid_formatter
      objectid_formatter_class.new
    end

    def objectid_formatter_class
      "Chouette::ObjectidFormatter::#{read_attribute(:objectid_format).camelcase}".constantize if read_attribute(:objectid_format)
    end
  end
end
