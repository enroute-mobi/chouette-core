class ModelAttribute
  attr_reader :klass, :name, :data_type, :mandatory, :options

  def self.all
    @__all__ ||= []
  end

  def self.grouped_options(list: all, type: nil)
    group_by_class(list).reduce({}) do |options, (key, values)|
      values.reject!{ |x| x.data_type != type } if type
      key = I18n.t("activerecord.models.#{key}.one")
      options.merge(
        key => values.map { |i| [i.klass.tmf(i.name), "#{i.code}"] }
      )
    end
  end

  def self.define(**params)
    all << new(
      params[:klass],
      params[:name],
      params[:data_type] || :string,
      params[:mandatory] || false,
      params[:options] || {},
    )
  end

  def self.group_by_class(list = nil)
    (list || all).group_by(&:resource_name)
  end

  def self.find_by_code code
    all.find { |m| m.code == code }
  end

  def initialize(klass, name, data_type, mandatory=false, **options)
    @klass = klass
    @name = name
    @data_type = data_type
    @mandatory = mandatory
    @options = options
  end

  # Chouette::Line
  define klass: Chouette::Line, name: :name, mandatory: true
  define klass: Chouette::Line, name: :active_from, data_type: :date
  define klass: Chouette::Line, name: :active_until, data_type: :date
  define klass: Chouette::Line, name: :color
  define klass: Chouette::Line, name: :company, options: { reference: true }
  define klass: Chouette::Line, name: :network, options: { reference: true }
  define klass: Chouette::Line, name: :number
  define klass: Chouette::Line, name: :published_name
  define klass: Chouette::Line, name: :text_color
  define klass: Chouette::Line, name: :transport_mode
  define klass: Chouette::Line, name: :transport_submode
  define klass: Chouette::Line, name: :url

  # Chouette::Company
  define klass: Chouette::Company, name: :name, mandatory: true
  define klass: Chouette::Company, name: :short_name
  define klass: Chouette::Company, name: :code
  define klass: Chouette::Company, name: :customer_service_contact_email
  define klass: Chouette::Company, name: :customer_service_contact_more
  define klass: Chouette::Company, name: :customer_service_contact_name
  define klass: Chouette::Company, name: :customer_service_contact_phone
  define klass: Chouette::Company, name: :customer_service_contact_url
  define klass: Chouette::Company, name: :default_contact_email
  define klass: Chouette::Company, name: :default_contact_fax
  define klass: Chouette::Company, name: :default_contact_more
  define klass: Chouette::Company, name: :default_contact_name
  define klass: Chouette::Company, name: :default_contact_operating_department_name
  define klass: Chouette::Company, name: :default_contact_organizational_unit
  define klass: Chouette::Company, name: :default_contact_phone
  define klass: Chouette::Company, name: :default_contact_url
  define klass: Chouette::Company, name: :default_language
  define klass: Chouette::Company, name: :private_contact_email
  define klass: Chouette::Company, name: :private_contact_more
  define klass: Chouette::Company, name: :private_contact_name
  define klass: Chouette::Company, name: :private_contact_phone
  define klass: Chouette::Company, name: :private_contact_url
  define klass: Chouette::Company, name: :address_line_1
  define klass: Chouette::Company, name: :address_line_2
  define klass: Chouette::Company, name: :country, options: { source_attributes: [:country_code] }
  define klass: Chouette::Company, name: :country_code
  define klass: Chouette::Company, name: :house_number
  define klass: Chouette::Company, name: :postcode
  define klass: Chouette::Company, name: :postcode_extension
  define klass: Chouette::Company, name: :street
  define klass: Chouette::Company, name: :time_zone
  define klass: Chouette::Company, name: :town

  # Chouette::StopArea
  define klass: Chouette::StopArea, name: :name, mandatory: true
  define klass: Chouette::StopArea, name: :parent,  options: { reference: true }
  define klass: Chouette::StopArea, name: :referent,  options: { reference: true }
  define klass: Chouette::StopArea, name: :fare_code
  define klass: Chouette::StopArea, name: :coordinates, options: { source_attributes: [:latitude, :longitude] }
  define klass: Chouette::StopArea, name: :country, options: { source_attributes: [:country_code] }
  define klass: Chouette::StopArea, name: :country_code
  define klass: Chouette::StopArea, name: :street_name
  define klass: Chouette::StopArea, name: :zip_code
  define klass: Chouette::StopArea, name: :city_name
  define klass: Chouette::StopArea, name: :url
  define klass: Chouette::StopArea, name: :time_zone
  define klass: Chouette::StopArea, name: :waiting_time, data_type: :integer
  define klass: Chouette::StopArea, name: :postal_region
  define klass: Chouette::StopArea, name: :public_code
  define klass: Chouette::StopArea, name: :compass_bearing, data_type: :float
  define klass: Chouette::StopArea, name: :accessibility_limitation_description

  # Chouette::Route
  define klass: Chouette::Route, name: :name, mandatory: true
  define klass: Chouette::Route, name: :published_name
  define klass: Chouette::Route, name: :opposite_route, options: { reference: true }
  define klass: Chouette::Route, name: :wayback

  # Chouette::JourneyPattern
  define klass: Chouette::JourneyPattern, name: :name, mandatory: true
  define klass: Chouette::JourneyPattern, name: :published_name
  define klass: Chouette::JourneyPattern, name: :shape, options: { reference: true }

  # Chouette::VehicleJourney
  define klass: Chouette::VehicleJourney, name: :published_journey_name
  define klass: Chouette::VehicleJourney, name: :company, options: { reference: true }
  define klass: Chouette::VehicleJourney, name: :transport_mode
  define klass: Chouette::VehicleJourney, name: :published_journey_identifier

  # Chouette::Footnote
  define klass: Chouette::Footnote, name: :code
  define klass: Chouette::Footnote, name: :label

  # Chouette::RoutingConstraintZone
  define klass: Chouette::RoutingConstraintZone, name: :name, mandatory: true

  def code
    "#{resource_name}##{name}"
  end

  def resource_name
    klass.model_name.param_key.to_sym
  end

  def collection_name
    klass.model_name.plural.to_sym
  end

  def ==(other)
    self.class === other &&
      klass == other.klass &&
      name == other.name &&
      data_type == other.data_type &&
      mandatory == other.mandatory &&
      options == other.options
  end
end