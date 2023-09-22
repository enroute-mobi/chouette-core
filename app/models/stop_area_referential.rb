class StopAreaReferential < ApplicationModel
  STOPS_SELECTION_DISPLAYABLE_FIELDS = %i(
    formatted_area_type local_id zip_code city_name postal_region country_name
  )
  validates :registration_number_format, format: { with: /\AX*\z/ }

  include ObjectidFormatterSupport
  has_many :stop_area_referential_memberships, dependent: :destroy
  has_many :organisations, through: :stop_area_referential_memberships

  has_many :stop_areas, class_name: 'Chouette::StopArea', dependent: :destroy
  has_many :connection_links, class_name: 'Chouette::ConnectionLink', dependent: :destroy
  has_many :workbenches, dependent: :nullify
  has_one  :workgroup, dependent: :nullify
  has_many :stop_area_providers
  has_many :stop_area_routing_constraints, dependent: :destroy
  has_many :entrances, dependent: :destroy
  # has_many :fare_providers, dependent: :destroy, class_name: 'Fare::Provider'
  has_many :fare_zones, through: :workbenches

  def add_member(organisation, options = {})
    attributes = options.merge organisation: organisation
    stop_area_referential_memberships.build attributes unless organisations.include?(organisation)
  end

  def available_countries
    stop_areas.select(:country_code).uniq.compact.map &:country
  end

  def available_stops
    route_edition_available_stops.map{|k,v| k if v}.compact
  end

  def generate_registration_number
    return "" unless registration_number_format.present?
    last = self.stop_areas.order("registration_number DESC NULLS LAST").limit(1).first&.registration_number
    if self.stop_areas.count == 26**self.registration_number_format.size
      raise "NO MORE AVAILABLE VALUES FOR registration_number in referential #{self.name}"
    end

    return "A" * self.registration_number_format.size unless last

    if last == "Z" * self.registration_number_format.size
      val = "A" * self.registration_number_format.size
      while self.stop_areas.where(registration_number: val).exists?
        val = val.next
      end
      val
    else
      last.next
    end
  end

  def validates_registration_number value
    return false unless value.size == registration_number_format.size
    return false unless value =~ /^[A-Z]*$/
    true
  end

  def self.translate_code_to_official(code)
    return 'en_GB' if code.to_s == 'en_UK'

    code
  end

  def self.translate_code_to_internal(code)
    return 'en_UK' if code.to_s == 'en_GB'

    code
  end

  def translate_code_to_official(code)
    self.class.translate_code_to_official(code)
  end

  def locale_name(locale)
     ISO3166::Country[translate_code_to_official(locale[:code]).split('_').last].translation(I18n.locale)
  end

  def locales
    self[:locales].map &:with_indifferent_access
  end

  def sorted_locales
    locales.sort_by{|l| locale_name(l)}
  end

  def enabled_stops_selection_displayed_fields
    stops_selection_displayed_fields.select {|k, v| v}.keys
  end
end
