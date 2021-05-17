class ModelAttribute
  attr_reader :klass, :name, :data_type, :options

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

  def self.define(klass, name, data_type, **options)
    all << new(klass, name, data_type, options)
  end

  def self.group_by_class(list = nil)
    (list || all).group_by(&:resource_name)
  end

  def initialize(klass, name, data_type, **options)
    @klass = klass
    @name = name
    @data_type = data_type
    
    @options = options
  end

  # Chouette::Route
  define Chouette::Route, :name, :string, **{ mandatory: true }
  define Chouette::Route, :published_name, :string, **{ mandatory: true }

  # Chouette::JourneyPattern
  define Chouette::JourneyPattern, :name, :string, **{ mandatory: true }
  define Chouette::JourneyPattern, :published_name, :string, **{ mandatory: true }
  define Chouette::JourneyPattern, :registration_number, :string

  # Chouette::VehicleJourney
  define Chouette::VehicleJourney, :published_journey_name, :string
  define Chouette::VehicleJourney, :published_journey_identifier, :string

  # Chouette::Footnote
  define Chouette::Footnote, :code, :string
  define Chouette::Footnote, :label, :string

  # Chouette::RoutingConstraintZone
  define Chouette::RoutingConstraintZone, :name, :string, **{ mandatory: true }

  # Chouette::Line
  define Chouette::Line, :published_name, :string, **{ mandatory: true }
  define Chouette::Line, :number, :string
  define Chouette::Line, :company_id, :integer
  define Chouette::Line, :network_id, :integer
  define Chouette::Line, :color, :string
  define Chouette::Line, :text_color, :string
  define Chouette::Line, :url, :string
  define Chouette::Line, :transport_mode, :string
  
  # Chouette::StopArea
  define Chouette::StopArea, :street_name, :string
  define Chouette::StopArea, :zip_code, :string
  define Chouette::StopArea, :city_name, :string
  define Chouette::StopArea, :postal_region, :string
  define Chouette::StopArea, :country_code, :string
  define Chouette::StopArea, :time_zone, :string
  define Chouette::StopArea, :fare_code, :string
  define Chouette::StopArea, :coordinates, :string

  # Chouette::Company
  define Chouette::Company, :default_contact_url, :float
  define Chouette::Company, :default_contact_phone, :float

  def code
    "#{resource_name}##{name}"
  end

  def resource_name
    klass.model_name.param_key.to_sym
  end

  def collection_name
    klass.model_name.plural.to_sym
  end

  def mandatory
    options[:mandatory]
  end

   def ==(other)
    self.class === other &&
      klass == other.klass &&
      name == other.name &&
      data_type == other.data_type
      options == other.options
  end
end
