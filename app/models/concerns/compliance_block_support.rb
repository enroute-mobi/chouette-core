module ComplianceBlockSupport
  extend ActiveSupport::Concern

  included do
    include TransportModeEnumerations
    
    store_accessor :condition_attributes,
      :block_kind,
      :transport_mode, :transport_submode,
      :country, :min_stop_areas_in_country

    validates :block_kind, presence: true
    validates :transport_mode, presence: true, if: :transport_mode?
    validates :country, :min_stop_areas_in_country, presence: true, if: :stop_areas_in_countries?

    validate :transport_mode_and_submode_match, if: :transport_mode?
  end

  def stop_areas_in_countries?
    block_kind.to_s == "stop_areas_in_countries"
  end

  def transport_mode?
    block_kind.blank? || block_kind.to_s == "transport_mode"
  end

  def accept_iev_controls?
    !stop_areas_in_countries?
  end

  def block_name
    if transport_mode?
      transport_mode_t = "enumerize.transport_mode.#{transport_mode}".t
      if transport_submode.present?
        transport_submode_t = "enumerize.transport_submode.#{transport_submode}".t
        'compliance_control_blocks.with_transport_submode'.t(transport_mode: transport_mode_t, transport_submode: transport_submode_t)
      else
        'compliance_control_blocks.with_transport_mode'.t(transport_mode: transport_mode_t)
      end
    else
      'compliance_control_blocks.stop_areas_in_countries'.t(country_name: ISO3166::Country[country].translation(I18n.locale), min_count: min_stop_areas_in_country)
    end
  end
end
