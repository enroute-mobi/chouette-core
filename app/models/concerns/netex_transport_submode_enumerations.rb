module NetexTransportSubmodeEnumerations
  extend ActiveSupport::Concern

  included do
    extend Enumerize
    enumerize :transport_submode, in: NetexTransportSubmodeEnumerations.transport_submodes
  end

  module ClassMethods
    def transport_submodes
      NetexTransportSubmodeEnumerations.transport_submodes
    end

    def sorted_transport_submodes
      NetexTransportSubmodeEnumerations.sorted_transport_submodes
    end
  end

  class << self
    def transport_submodes
      %w(
        demandAndResponseBus
        nightBus
        airportLinkBus
        highFrequencyBus
        expressBus
        railShuttle
        suburbanRailway
        regionalRail
        interregionalRail
      )
    end

    def sorted_transport_submodes
      transport_submodes.sort_by do |m|
        I18n.t("enumerize.transport_submode.#{m}").parameterize
      end
    end
  end
end
