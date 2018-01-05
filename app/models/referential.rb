# coding: utf-8
class Referential < ActiveRecord::Base
  include DataFormatEnumerations
  include ObjectidFormatterSupport

  validates_presence_of :name
  validates_presence_of :slug
  validates_presence_of :prefix
  # Fixme #3657
  # validates_presence_of :time_zone
  # validates_presence_of :upper_corner
  # validates_presence_of :lower_corner

  validates_uniqueness_of :slug

  validates_format_of :slug, with: %r{\A[a-z][0-9a-z_]+\Z}
  validates_format_of :prefix, with: %r{\A[0-9a-zA-Z_]+\Z}
  validates_format_of :upper_corner, with: %r{\A-?[0-9]+\.?[0-9]*\,-?[0-9]+\.?[0-9]*\Z}
  validates_format_of :lower_corner, with: %r{\A-?[0-9]+\.?[0-9]*\,-?[0-9]+\.?[0-9]*\Z}
  validate :slug_excluded_values

  attr_accessor :upper_corner
  attr_accessor :lower_corner

  has_one :user
  has_many :api_keys, class_name: 'Api::V1::ApiKey', dependent: :destroy

  belongs_to :organisation
  validates_presence_of :organisation
  validate def validate_consistent_organisation
    return true if workbench_id.nil?
    ids = [workbench.organisation_id, organisation_id]
    return true if ids.first == ids.last
    errors.add(:inconsistent_organisation,
               I18n.t('referentials.errors.inconsistent_organisation',
                      indirect_name: workbench.organisation.name,
                      direct_name: organisation.name))
  end, if: :organisation

  belongs_to :line_referential
  validates_presence_of :line_referential

  belongs_to :created_from, class_name: 'Referential'
  has_many :associated_lines, through: :line_referential, source: :lines
  has_many :companies, through: :line_referential
  has_many :group_of_lines, through: :line_referential
  has_many :networks, through: :line_referential
  has_many :metadatas, class_name: "ReferentialMetadata", inverse_of: :referential, dependent: :destroy, after_remove: :did_update_metadatas
  accepts_nested_attributes_for :metadatas

  belongs_to :stop_area_referential
  validates_presence_of :stop_area_referential
  has_many :stop_areas, through: :stop_area_referential
  belongs_to :workbench

  belongs_to :referential_suite


  scope :ready, -> { where(ready: true) }
  scope :in_periode, ->(periode) { where(id: referential_ids_in_periode(periode)) }
  scope :include_metadatas_lines, ->(line_ids) { where('referential_metadata.line_ids && ARRAY[?]::bigint[]', line_ids) }
  scope :order_by_validity_period, ->(dir) { joins(:metadatas).order("unnest(periodes) #{dir}") }
  scope :order_by_lines, ->(dir) { joins(:metadatas).group("referentials.id").order("sum(array_length(referential_metadata.line_ids,1)) #{dir}") }

  def save_with_table_lock_timeout(options = {})
    save_without_table_lock_timeout(options)
  rescue ActiveRecord::StatementInvalid => e
    if e.message.include?('PG::LockNotAvailable')
      raise TableLockTimeoutError.new(e)
    else
      raise
    end
  end

  alias_method_chain :save, :table_lock_timeout

  def lines
    if metadatas.blank?
      workbench ? workbench.lines : associated_lines
    else
      metadatas_lines
    end
  end

  def slug_excluded_values
    if ! slug.nil?
      if slug.start_with? "pg_"
        errors.add(:slug,I18n.t("referentials.errors.pg_excluded"))
      end
      if slug == 'public'
        errors.add(:slug,I18n.t("referentials.errors.public_excluded"))
      end
      if slug == self.class.connection_config[:username]
        errors.add(:slug,I18n.t("referentials.errors.user_excluded", user: slug))
      end
    end
  end

  def viewbox_left_top_right_bottom
    [  lower_corner.lng, upper_corner.lat, upper_corner.lng, lower_corner.lat ].join(',')
  end

  def human_attribute_name(*args)
    self.class.human_attribute_name(*args)
  end

  def stop_areas
    Chouette::StopArea.all
  end

  def access_points
    Chouette::AccessPoint.all
  end

  def access_links
    Chouette::AccessLink.all
  end

  def time_tables
    Chouette::TimeTable.all
  end

  def timebands
    Chouette::Timeband.all
  end

  def connection_links
    Chouette::ConnectionLink.all
  end

  def vehicle_journeys
    Chouette::VehicleJourney.all
  end

  def vehicle_journey_frequencies
    Chouette::VehicleJourneyFrequency.all
  end

  def routing_constraint_zones
    Chouette::RoutingConstraintZone.all
  end

  def purchase_windows
    Chouette::PurchaseWindow.all
  end

  before_validation :define_default_attributes

  def define_default_attributes
    self.time_zone ||= Time.zone.name
    self.objectid_format ||= workbench.objectid_format if workbench
  end

  def switch
    raise "Referential not created" if new_record?
    Apartment::Tenant.switch!(slug)
    self
  end

  def self.new_from(from, functional_scope)
    new_referential = Referential.new(
      name: I18n.t("activerecord.copy", name: from.name),
      slug: "#{from.slug}_clone",
      prefix: from.prefix,
      time_zone: from.time_zone,
      bounds: from.bounds,
      line_referential: from.line_referential,
      stop_area_referential: from.stop_area_referential,
      created_from: from,
      objectid_format: from.objectid_format,
      metadatas: from.metadatas.map { |m| ReferentialMetadata.new_from(m, functional_scope) }
    )
    yield new_referential if block_given?

    new_referential
  end

  def self.available_srids
    [
      [ "RGF 93 Lambert 93 (2154)", 2154 ],
      [ "RGF93 CC42 (zone 1) (3942)", 3942 ],
      [ "RGF93 CC43 (zone 2) (3943)", 3943 ],
      [ "RGF93 CC44 (zone 3) (3944)", 3944 ],
      [ "RGF93 CC45 (zone 4) (3945)", 3945 ],
      [ "RGF93 CC46 (zone 5) (3946)", 3946 ],
      [ "RGF93 CC47 (zone 6) (3947)", 3947 ],
      [ "RGF93 CC48 (zone 7) (3948)", 3948 ],
      [ "RGF93 CC49 (zone 8) (3949)", 3949 ],
      [ "RGF93 CC50 (zone 9) (3950)", 3950 ],
      [ "NTF Lambert Zone 1 Nord (27561)", 27561 ],
      [ "NTF Lambert Zone 2 Centre (27562)", 27562 ],
      [ "NTF Lambert Zone 3 Sud (27563)", 27563 ],
      [ "NTF Lambert Zone 4 Corse (27564)", 27564 ],
      [ "NTF Lambert 1 Carto (27571)", 27571 ],
      [ "NTF Lambert 2 Carto (27572)", 27572 ],
      [ "NTF Lambert 3 Carto (27573)", 27573 ],
      [ "NTF Lambert 4 Carto (27574)", 27574 ] ,
      [ "Réunion RGR92 - UTM 40S (2975)", 2975 ],
      [ "Antilles Françaises RRAF1991 - UTM 20N - IGN (4559)", 4559 ],
      [ "Guyane RGFG95 - UTM 22N (2972)", 2972 ],
      [ "Guyane RGFG95 - UTM 21N (3312)", 3312 ]
    ]
  end

  def projection_type_label
    self.class.available_srids.each do |a|
      if a.last.to_s == projection_type
        return a.first.split('(').first.rstrip
      end
    end
    projection_type || ""
  end

  before_validation :assign_line_and_stop_area_referential, on: :create, if: :workbench
  before_validation :assign_slug, on: :create
  before_validation :assign_prefix, on: :create

  # Lock the `referentials` table to prevent duplicate referentials from being
  # created simultaneously in separate transactions. This must be the last hook
  # to minimise the duration of the lock.
  before_save :lock_table, on: [:create, :update]

  before_create :create_schema
  after_create :clone_schema, if: :created_from
  after_save :perform_cleanup_if_needed

  before_destroy :destroy_schema
  before_destroy :destroy_jobs

  def perform_cleanup_if_needed
    return unless ready_changed? && ready
    perform_cleanup
  end

  def in_workbench?
    workbench_id.present?
  end

  def init_metadatas(attributes = {})
    if metadatas.blank?
      date_range = attributes.delete :default_date_range
      metadata = metadatas.build attributes
      metadata.periodes = [date_range] if date_range
    end
  end

  def metadatas_period
    query = "select min(lower), max(upper) from (select lower(unnest(periodes)) as lower, upper(unnest(periodes)) as upper from public.referential_metadata where public.referential_metadata.referential_id = #{id}) bounds;"

    row = self.class.connection.select_one(query)
    lower, upper = row["min"], row["max"]

    if lower and upper
      Range.new(Date.parse(lower), Date.parse(upper)-1)
    end
  end
  alias_method :validity_period, :metadatas_period

  def metadatas_lines
    if metadatas.present?
      associated_lines.where(id: metadatas.pluck(:line_ids).flatten)
    else
      Chouette::Line.none
    end
  end

  def self.referential_ids_in_periode(range)
    subquery = "SELECT DISTINCT(public.referential_metadata.referential_id) FROM public.referential_metadata, LATERAL unnest(periodes) period "
    subquery << "WHERE period && '#{range_to_string(range)}'"
    query = "SELECT * FROM public.referentials WHERE referentials.id IN (#{subquery})"
    self.connection.select_values(query).map(&:to_i)
  end

  # Copied from Rails 4.1 activerecord/lib/active_record/connection_adapters/postgresql/cast.rb
  # TODO: Relace with the appropriate Rais 4.2 / 5.x helper if one is found.
  def self.range_to_string(object)
    from = object.begin.respond_to?(:infinite?) && object.begin.infinite? ? '' : object.begin
    to   = object.end.respond_to?(:infinite?) && object.end.infinite? ? '' : object.end
    "[#{from},#{to}#{object.exclude_end? ? ')' : ']'}"
  end

  def overlapped_referential_ids
    return [] unless metadatas.present?

    line_ids = metadatas.first.line_ids
    periodes = metadatas.first.periodes

    return [] unless line_ids.present? && periodes.present?

    not_myself = "and referential_id != #{id}" if persisted?

    periods_query = periodes.map do |periode|
      "period && '[#{periode.begin},#{periode.end})'"
    end.join(" OR ")

    query = "select distinct(public.referential_metadata.referential_id) FROM public.referential_metadata, unnest(line_ids) line, LATERAL unnest(periodes) period
    WHERE public.referential_metadata.referential_id
    IN (SELECT public.referentials.id FROM public.referentials WHERE referentials.workbench_id = #{workbench_id} and referentials.archived_at is null #{not_myself})
    AND line in (#{line_ids.join(',')}) and (#{periods_query});"

    self.class.connection.select_values(query).map(&:to_i)
  end

  def metadatas_overlap?
    overlapped_referential_ids.present?
  end

  validate :detect_overlapped_referentials

  def detect_overlapped_referentials
    self.class.where(id: overlapped_referential_ids).each do |referential|
      Rails.logger.info "Referential #{referential.id} #{referential.metadatas.inspect} overlaps #{metadatas.inspect}"
      errors.add :metadatas, I18n.t("referentials.errors.overlapped_referential", :referential => referential.name)
    end
  end

  def clone_schema
    ReferentialCloning.create(source_referential: created_from, target_referential: self)
  end

  def create_schema
    unless created_from
      report = Benchmark.measure do
        Apartment::Tenant.create slug
      end

      Rails.logger.info("Schema create benchmark: '#{slug}'\t#{report}")
      Rails.logger.error( "Schema migrations count for Referential #{slug} " + Referential.connection.select_value("select count(*) from #{slug}.schema_migrations;").to_s )
    end
  end

  def assign_slug
    self.slug ||= "#{name.parameterize.gsub('-', '_')}_#{Time.now.to_i}" if name
  end

  def assign_prefix
    self.prefix = organisation.name.parameterize.gsub('-', '_') if organisation
  end

  def assign_line_and_stop_area_referential
    self.line_referential = workbench.line_referential
    self.stop_area_referential = workbench.stop_area_referential
  end

  def destroy_schema
    Apartment::Tenant.drop slug
  end

  def destroy_jobs
    #Ievkit.delete_jobs(slug)
    true
  end

  def upper_corner
    envelope.upper_corner
  end

  def upper_corner=(upper_corner)
    if String === upper_corner
      upper_corner = (upper_corner.blank? ? nil : GeoRuby::SimpleFeatures::Point::from_lat_lng(Geokit::LatLng.normalize(upper_corner), 4326))
    end

    envelope.tap do |envelope|
      envelope.upper_corner = upper_corner
      self.bounds = envelope.to_polygon.as_ewkt
    end
  end

  def lower_corner
    envelope.lower_corner
  end

  def lower_corner=(lower_corner)
    if String === lower_corner
      lower_corner = (lower_corner.blank? ? nil : GeoRuby::SimpleFeatures::Point::from_lat_lng(Geokit::LatLng.normalize(lower_corner), 4326))
    end

    envelope.tap do |envelope|
      envelope.lower_corner = lower_corner
      self.bounds = envelope.to_polygon.as_ewkt
    end
  end

  def default_bounds
    GeoRuby::SimpleFeatures::Envelope.from_coordinates( [ [-5.2, 42.25], [8.23, 51.1] ] ).to_polygon.as_ewkt
  end

  def envelope
    bounds = read_attribute(:bounds)
    GeoRuby::SimpleFeatures::Geometry.from_ewkt(bounds.present? ? bounds : default_bounds ).envelope
  end

  # Archive
  def archived?
    archived_at != nil
  end

  def archive!
    # self.archived = true
    touch :archived_at
  end
  def unarchive!
    return false unless can_unarchive?
    # self.archived = false
    update_column :archived_at, nil
  end

  def can_unarchive?
    not metadatas_overlap?
  end

  def did_update_metadatas args=nil
    return unless ready?
    perform_cleanup
  end

  def perform_cleanup
    remaining_line_ids = self.metadatas.reload.pluck(:line_ids).flatten.uniq
    switch
    Chouette::Route.where.not(line_id: remaining_line_ids).destroy_all
  end

  private

  def lock_table
    # No explicit unlock is needed as it will be released at the end of the
    # transaction.
    ActiveRecord::Base.connection.execute(
      'LOCK referentials IN ACCESS EXCLUSIVE MODE'
    )
  end

end
