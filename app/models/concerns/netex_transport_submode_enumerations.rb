module NetexTransportSubmodeEnumerations
  extend ActiveSupport::Concern

  included do
    extend Enumerize
    enumerize :transport_submode, in: NetexTransportSubmodeEnumerations.transport_submodes
  end

  def transport_mode_and_submode_match
    return unless transport_mode.present?

    submodes = NetexTransportSubmodeEnumerations.submodes_for_transports

    return if submodes[transport_mode&.to_sym].blank? && transport_submode.blank?
    return if submodes[transport_mode&.to_sym]&.include?(transport_submode.presence)

    errors.add(:transport_mode, :submode_mismatch)
  end

  module ClassMethods
    def transport_submodes
      NetexTransportSubmodeEnumerations.transport_submodes
    end

    def formatted_submodes_for_transports
      NetexTransportSubmodeEnumerations.formatted_submodes_for_transports
    end
  end

  class << self
    def transport_submodes
      submodes_for_transports.values.flatten.uniq
    end

    def sorted_transport_submodes
      transport_submodes.compact.sort_by do |m|
        I18n.t("enumerize.transport_submode.#{m}").parameterize
      end
    end

    def submodes_for_transports
      {
        tram: [
          "undefined",
        ],
        metro: [
          "undefined",
        ],
        funicular: [
          "undefined",
        ],
        bus: [
          "undefined",
          "demandAndResponseBus",
          "nightBus",
          "airportLinkBus",
          "highFrequencyBus",
          "expressBus"
        ],
        rail: %w(
          railShuttle
          suburbanRailway
          regionalRail
          interregionalRail
        )
      }
    end

    def formatted_submodes_for_transports
      submodes_for_transports.map do |t,s|
        {
          t => s.map do |k|
            [I18n.t("enumerize.transport_submode.#{ k.presence || 'undefined' }"), k]
          end.sort_by { |k| k.last ? k.first : "" }
        }
      end.reduce({}, :merge)
    end
  end
end
