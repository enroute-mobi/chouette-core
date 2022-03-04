class ModelAttribute

  MODELS = [
    Chouette::Line,
    Chouette::Company,
    Chouette::StopArea,
    Chouette::Route,
    Chouette::JourneyPattern,
    Chouette::VehicleJourney,
    Chouette::Footnote,
    Chouette::RoutingConstraintZone,
  ]

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

  def self.find_by_code code
    all.find { |m| m.code == code }
  end

  def initialize(klass, name, data_type, **options)
    @klass = klass
    @name = name
    @data_type = data_type
    
    @options = options
  end

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

  def self.associations(model)
    associations = model.reflect_on_all_associations
    associations = associations.select { |a| a.macro == :belongs_to }
    associations.map{ |a| ["#{a.name}_id", a.name] }.to_h
  end

  # create automatically all model_attributes from DB
  MODELS.each do |model|
    refs = self.associations(model)

    model.columns_hash.each do |attr_name, attr_infos|
      options = attr_infos.null ? {} : { mandatory: !attr_infos.null }
      options[:ref] = refs[attr_name] if refs[attr_name]
      define model, attr_name, attr_infos.type, options
    end
  end
end
