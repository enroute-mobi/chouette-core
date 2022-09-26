# coding: utf-8

module ReferentialSaveWithLock
  def save(options = {})
    super(options)
  rescue ActiveRecord::StatementInvalid => e
    Chouette::Safe.capture "Referential #{name} with slug #{slug} save failed", e

    if e.message.include?('PG::LockNotAvailable')
      raise TableLockTimeoutError.new(e)
    else
      raise
    end
  end
end

class Referential < ApplicationModel
  prepend ReferentialSaveWithLock

  include DataFormatEnumerations
  include ObjectidFormatterSupport

  STATES = %i(pending active failed archived)
  TIME_BEFORE_CLEANING = SmartEnv['REFERENTIALS_CLEANING_COOLDOWN']
  KEPT_DURING_CLEANING = 20

  validates_presence_of :name
  validates_presence_of :slug
  validates_presence_of :prefix
  # Fixme #3657
  # validates_presence_of :time_zone
  # validates_presence_of :upper_corner
  # validates_presence_of :lower_corner

  validates_uniqueness_of :slug

  validates_format_of :prefix, with: %r{\A[0-9a-zA-Z_]+\Z}
  # validates_format_of :upper_corner, with: %r{\A-?[0-9]+\.?[0-9]*\,-?[0-9]+\.?[0-9]*\Z}
  # validates_format_of :lower_corner, with: %r{\A-?[0-9]+\.?[0-9]*\,-?[0-9]+\.?[0-9]*\Z}

  attr_accessor :upper_corner
  attr_accessor :lower_corner

  attr_accessor :from_current_offer
  attr_accessor :urgent
  attr_accessor :bare #this is used in specs to skip schema creation

  has_one :user
  has_many :import_resources, class_name: 'Import::Resource', dependent: :destroy
  has_many :compliance_check_sets, dependent: :nullify
  has_many :clean_ups, dependent: :destroy

  belongs_to :organisation
  validates_presence_of :organisation
  validate def validate_consistent_organisation
    return true if workbench_id.nil?
    ids = [workbench.organisation_id, organisation_id]
    return true if ids.first == ids.last
    errors.add(:inconsistent_organisation,
               I18n.t('referentials.errors.inconsistent_organisation',
                      indirect_name: workbench.name,
                      direct_name: organisation.name))
  end, if: :organisation

  belongs_to :line_referential
  validates_presence_of :line_referential

  belongs_to :created_from, class_name: 'Referential'
  has_many :associated_lines, through: :line_referential, source: :lines
  has_many :companies, through: :line_referential
  has_many :group_of_lines, through: :line_referential
  has_many :networks, through: :line_referential
  has_many :line_providers, through: :line_referential
  has_many :metadatas, class_name: "ReferentialMetadata", inverse_of: :referential, dependent: :delete_all
  accepts_nested_attributes_for :metadatas

  belongs_to :stop_area_referential
  validates_presence_of :stop_area_referential
  has_many :stop_areas, through: :stop_area_referential
  has_many :stop_area_providers, through: :stop_area_referential

  belongs_to :workbench

  belongs_to :referential_suite

  scope :pending, -> { where(ready: false, failed_at: nil, archived_at: nil) }
  scope :active, -> { where(ready: true, failed_at: nil, archived_at: nil) }
  scope :failed, -> { where.not(failed_at: nil) }
  scope :archived, -> { where.not(archived_at: nil) }
  scope :inactive_and_not_pending, -> { where('failed_at IS NOT NULL OR archived_at IS NOT NULL') }

  scope :ready, -> { where(ready: true) }
  scope :exportable, -> {
    joins("LEFT JOIN public.referential_suites ON referentials.referential_suite_id = referential_suites.id").where("ready = ? AND merged_at IS NULL AND (referential_suite_id IS NULL OR referential_suites.current_id = referentials.id)", true)
  }
  scope :autocomplete, ->(q) {
    if q.present?
      where("name ILIKE '%#{sanitize_sql_like(q)}%'")
    else
      all
    end
  }

  scope :in_periode, ->(periode) { where(id: referential_ids_in_periode(periode)) }
  scope :include_metadatas_lines, ->(line_ids) { joins(:metadatas).where('referential_metadata.line_ids && ARRAY[?]::bigint[]', line_ids) }
  scope :order_by_validity_period, ->(dir) { joins(:metadatas).order(Arel.sql("unnest(periodes) #{dir}")) }
  scope :order_by_lines, ->(dir) { joins(:metadatas).group("referentials.id").order(Arel.sql("sum(array_length(referential_metadata.line_ids,1)) #{dir}")) }
  scope :order_by_organisation_name, ->(dir) { joins(:organisation).order(Arel.sql("lower(organisations.name) #{dir}")) }
  scope :not_in_referential_suite, -> { where referential_suite_id: nil }
  scope :blocked, -> { where('ready = ? AND created_at < ?', false, 4.hours.ago) }
  scope :created_before, -> (date) { where('created_at < ? ', date) }

  scope :clean_scope, -> {
    return none unless TIME_BEFORE_CLEANING > 0

    kept = []
    kept << archived.where('archived_at >= ?', TIME_BEFORE_CLEANING.days.ago).select(:id).to_sql
    kept << order('created_at DESC').limit(KEPT_DURING_CLEANING).select(:id).to_sql

    scope = inactive_and_not_pending.not_in_referential_suite
    kept.each do |kept_scope|
      scope = scope.where("referentials.id NOT IN (#{kept_scope})")
    end
    scope.joins('LEFT JOIN public.referential_metadata ON referential_metadata.referential_source_id = referentials.id').where('referential_metadata.id' => nil)
  }

  after_save :notify_state
  after_destroy :clean_cross_referential_index!

  def self.clean!
    Rails.logger.info "Cleaning Referentials (cooldown: #{TIME_BEFORE_CLEANING} days)"
    clean_scope.pluck(:id, :slug).each do |id, slug|
      Rails.logger.info "Clean Referential #{id} #{slug}"
    end
    clean_scope.destroy_all
  end

  def self.order_by_state(dir)
    states = ["ready #{dir}", "archived_at #{dir}", "failed_at #{dir}"]
    states.reverse! if dir == 'asc'
    Referential.order(*states)
  end

  def self.force_register_models_with_checksum
    paths = Rails.application.paths['app/models'].to_a
    Rails.application.railties.each do |tie|
      next unless tie.respond_to? :paths
      paths += tie.paths['app/models'].to_a
    end

    paths.each do |path|
      next unless File.directory?(path)
      Dir.chdir path do
        Dir['**/*.rb'].each do |src|
          next if src =~ /^concerns/
          # thanks for inconsistent naming ...
          if src == "route_control/zdl_stop_area.rb"
            RouteControl::ZDLStopArea
            next
          end
          Rails.logger.info "Loading #{src}"
          begin
            src[0..-4].classify.safe_constantize
          rescue => e
            Chouette::Safe.capture "Referential#force_register_models_with_checksum failed on #{src}", e
            nil
          end
        end
      end
    end
  end

  def self.register_model_with_checksum klass
    @_models_with_checksum ||= []
    @_models_with_checksum << klass
  end

  def self.models_with_checksum
    @_models_with_checksum || []
  end

  OPERATIONS = [Import::Netex, Import::Gtfs, CleanUp, Merge, Aggregate]

  def last_operation
    operations = []
    Referential::OPERATIONS.each do |klass|
      operations << klass.for_referential(self).limit(1).select("'#{klass.name}' as kind, id, created_at").order('created_at DESC').to_sql
    end
    sql = "SELECT * FROM ((#{operations.join(') UNION (')})) AS subquery ORDER BY subquery.created_at DESC"
    res = ActiveRecord::Base.connection.execute(sql).first
    if res
      res["kind"].constantize.find(res["id"])
    end
  end

  def audit
    ReferentialAudit::FullReferential.new(self).perform
    nil
  end

  def notify_state
    Notification.create! channel: "/referentials/#{self.id}", payload: {state: self.state}
  end

  def contains_urgent_offer?
    metadatas.any? { |m| m.urgent? }
  end

  def flagged_urgent_at
    metadatas.pluck(:flagged_urgent_at).compact.max
  end

  def flag_metadatas_as_urgent!
    if metadatas.loaded?
      metadatas.each { |m| m.flagged_urgent_at ||= Time.now }
    else
      metadatas.where(flagged_urgent_at: nil).update_all flagged_urgent_at: Time.now
    end
  end

  def flag_not_urgent!
    if metadatas.loaded?
      metadatas.each { |m| m.flagged_urgent_at = nil }
    else
      metadatas.update_all flagged_urgent_at: nil
    end
  end

  def lines
    if metadatas.blank?
      workbench ? workbench.lines : associated_lines
    else
      metadatas_lines
    end
  end

  def lines_outside_of_scope
    return lines.none unless workbench
    func_scope = workbench.workbench_scopes.lines_scope(associated_lines).pluck(:objectid)
    lines.where.not(objectid: func_scope)
  end

  def clean_routes_if_needed
    return unless persisted?
    line_ids = self.metadatas.pluck(:line_ids).flatten.uniq
    if self.switch { routes.where.not(line_id: line_ids).exists? }
      CleanUp.create!(referential: self, original_state: self.state)
      pending! && save!
    end
  end

  def viewbox_left_top_right_bottom
    [  lower_corner.lng, upper_corner.lat, upper_corner.lng, lower_corner.lat ].join(',')
  end

  def human_attribute_name(*args)
    self.class.human_attribute_name(*args)
  end

  def full_name
    if in_referential_suite?
      name
    else
      "#{self.class.model_name.human.capitalize} #{name}"
    end
  end

  def time_tables
    Chouette::TimeTable.all
  end

  def time_table_dates
    Chouette::TimeTableDate.all
  end

  def time_table_periods
    Chouette::TimeTablePeriod.all
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

  def vehicle_journey_at_stops
    Chouette::VehicleJourneyAtStop.all
  end

  def routing_constraint_zones
    Chouette::RoutingConstraintZone.all
  end

  def routes
    Chouette::Route.all
  end

  def journey_patterns
    Chouette::JourneyPattern.all
  end

  def stop_points
    Chouette::StopPoint.all
  end

  def footnotes
    Chouette::Footnote.all
  end

  def vehicle_journey_footnote_relationships
    Chouette::VehicleJourneyFootnoteRelationship.all
  end

  def codes
    ReferentialCode.all
  end
  alias referential_codes codes

  def service_counts
    Stat::JourneyPatternCoursesByDate.all
  end
  alias journey_pattern_courses_by_date service_counts

  def anomaly_service_counts(weeks_before, weeks_after, maximum_difference, options={})
    query = <<~SQL
      SELECT
        percentage_difference_table.line_id,
        percentage_difference_table.date,
        percentage_difference_table.sum_count,
        percentage_difference_table.avg_sum,
        percentage_difference_table.percentage_difference
      FROM (
        SELECT
          sum_and_avg_table.line_id,
          sum_and_avg_table.date,
          sum_and_avg_table.sum_count,
          sum_and_avg_table.avg_sum,
          ABS((sum_and_avg_table.sum_count - sum_and_avg_table.avg_sum) / sum_and_avg_table.sum_count) * 100 AS percentage_difference
        FROM (
          SELECT
            A.line_id, A.date,
            SUM(A.count) AS sum_count,
            (
              SELECT
                avg_table.avg_sum
              FROM (
                SELECT
                  sum_table.line_id,
                  AVG(sum_table.sum_count) AS avg_sum
                FROM (
                  SELECT SUM(B.count) AS sum_count, B.line_id, B.date
                  FROM stat_journey_pattern_courses_by_dates B
                  WHERE B.date BETWEEN (B.date - #{7 * weeks_before}) AND (B.date + #{7 * weeks_after})
                  GROUP BY B.line_id, B.date
                ) AS sum_table
                WHERE (EXTRACT(dow from sum_table.date) = EXTRACT(dow from A.date))
                GROUP BY sum_table.line_id
              ) AS avg_table
              WHERE (avg_table.line_id = A.line_id)
            ) AS avg_sum
          FROM stat_journey_pattern_courses_by_dates A
          WHERE A.date BETWEEN (A.date - #{7 * weeks_before}) AND (A.date + #{7 * weeks_after})
          GROUP BY A.line_id, A.date
        ) AS sum_and_avg_table
        WHERE sum_and_avg_table.sum_count > 0
      ) AS percentage_difference_table
      WHERE percentage_difference_table.percentage_difference > #{maximum_difference}
      LIMIT #{options[:limit] || 1000}
      OFFSET #{(options[:limit] || 1000) *  (options[:page] || 1) - (options[:limit] || 1000)}
    SQL

    ::ActiveRecord::Base.connection.execute(query)
  end

  def workgroup
    @workgroup = begin
      workgroup = workbench&.workgroup
      if referential_suite
        workgroup ||= Workgroup.where(output_id: referential_suite.id).last
      end
      workgroup
    end
  end

  def circulation_start
    time_tables.used.order('start_date ASC').select(:start_date).first&.start_date
  end

  def circulation_end
    time_tables.used.order('end_date ASC').select(:end_date).last&.end_date
  end

  before_validation :define_default_attributes

  def define_default_attributes
    self.time_zone ||= Time.zone.name
    self.objectid_format ||= workbench.objectid_format if workbench
  end

  before_save :set_metadatas_urgency
  def set_metadatas_urgency
    return if urgent.nil?

    if urgent
      flag_metadatas_as_urgent!
    else
      flag_not_urgent!
    end
  end

  def switch(verbose: true, &block)
    raise "Referential not created" if new_record?

    unless block_given?
      Rails.logger.debug "Referential switch to #{slug}" if verbose
      Apartment::Tenant.switch! slug
      self
    else
      result = nil
      Apartment::Tenant.switch slug do
        Rails.logger.debug "Referential switch to #{slug}" if verbose
        result = yield self
      end
      Rails.logger.debug "Referential back" if verbose
      result
    end
  end

  def self.new_from(from, workbench)
    clone = Referential.new(
      name: I18n.t("activerecord.copy", name: from.name),
      organisation: workbench.organisation,
      prefix: from.prefix,
      time_zone: from.time_zone,
      bounds: from.bounds,
      line_referential: from.line_referential,
      stop_area_referential: from.stop_area_referential,
      created_from: from,
      objectid_format: from.objectid_format,
      metadatas: from.metadatas.map { |m| ReferentialMetadata.new_from(m, workbench) },
      ready: false
    )
    clone.metadatas = clone.metadatas.select(&:valid?)
    clone
  end

  def line_periods(max_priority: nil)
    LinePeriod.from self, max_priority: max_priority
  end

  class LinePeriod
    attr_reader :period
    attr_accessor :line_id

    def initialize(attributes = {})
      attributes.each { |k,v| send "#{k}=", v }
    end

    def period=(period)
      @period = self.class.cast_period(period)
    end

    def self.from(referential, max_priority: nil)
      Query.new(referential.id, max_priority: max_priority)
    end

    def self.cast_period(definition)
      if definition.is_a?(String) && definition =~ /\[([0-9-]+),([0-9-]+)\)/
        Range.new Date.parse($1), Date.parse($2)-1
      else
        definition
      end
    end

    def ==(other)
      other.respond_to?(:line_id) && other.respond_to?(:period) &&
        line_id == other.line_id && period == other.period
    end

    class Query
      include Enumerable

      def initialize(referential_id, max_priority: nil)
        @referential_id, @max_priority = referential_id, max_priority
      end
      attr_reader :referential_id, :max_priority

      def all
        @all ||= to_rows.map { |row| LinePeriod.new row }
      end

      delegate :each, :empty?, :inspect, to: :all

      def to_rows
        ActiveRecord::Base.connection.select_all to_sql
      end

      def max_priority_condition
        "AND priority > #{max_priority}" if max_priority
      end

      def to_sql
        """
        select unnest(line_ids) as line_id, period from public.referential_metadata,
        lateral unnest(periodes) as period where referential_id = #{referential_id} #{max_priority_condition}
        """.strip
      end

    end

  end

  before_validation :assign_line_and_stop_area_referential, on: :create, if: :workbench
  before_validation :assign_slug, on: :create
  before_validation :assign_prefix, on: :create

  before_create :create_schema

  # Don't use after_commit because of inline_clone (cf created_from)
  after_create :clone_schema, if: :created_from
  after_create :create_from_current_offer, if: :from_current_offer

  before_destroy :destroy_schema
  before_destroy :destroy_jobs

  def referential_read_only?
    !ready? || in_referential_suite? || archived?
  end

  def in_referential_suite?
    referential_suite_id.present?
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

  def associated_stop_areas
    stop_area_referential.stop_areas.joins(:routes)
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

  def lines_status
    @lines_status ||= LinesStatus.new(self)
  end

  class LinesStatus
    def initialize(referential)
      @referential = referential
    end

    attr_reader :referential

    def updated_at(line)
      updated_at_by_lines[line.id]
    end

    def as_json(_options = nil)
      lines.map do |line|
        {
          objectid: line.objectid,
          name: line.name,
          updated_at: updated_at(line)
        }
      end
    end

    private

    delegate :lines, :metadatas, to: :referential

    def updated_at_by_lines
      @updated_at_by_lines ||= ActiveRecord::Base.connection.select_rows(query).map do |line_id, time|
        [ line_id, database_timezone.parse(time) ]
      end.to_h
    end

    def database_timezone
      @database_timezone ||= Time.find_zone("UTC")
    end

    def query
      "select line_id, max(created_at) from (#{metadatas.select('unnest(line_ids) as line_id', :created_at).to_sql}) as s group by line_id"
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

    not_myself = "and referentials.id != #{id}" if persisted?

    periods_query = periodes.map do |periode|
      "period && '[#{periode.min},#{periode.max + 1.day})'"
    end.join(" OR ")

    query = "select distinct(public.referential_metadata.referential_id) FROM public.referential_metadata, unnest(line_ids) line, LATERAL unnest(periodes) period
    WHERE public.referential_metadata.referential_id
    IN (SELECT public.referentials.id FROM public.referentials WHERE referentials.workbench_id = #{workbench_id} and referentials.archived_at is null and referentials.referential_suite_id is null #{not_myself} AND referentials.failed_at IS NULL)
    AND line in (#{line_ids.join(',')}) and (#{periods_query});"

    self.class.connection.select_values(query).map(&:to_i)
  end

  def metadatas_overlap?
    overlapped_referential_ids.present?
  end

  validate :detect_overlapped_referentials, unless: -> { in_referential_suite? || archived? }

  def detect_overlapped_referentials
    begin
      lock_table
    rescue ActiveRecord::StatementInvalid
      # Can occur when no transaction is started
      Rails.logger.warn "Can't retrieve lock before validating Referential #{slug}"
    end

    self.class.where(id: overlapped_referential_ids).each do |referential|
      Rails.logger.info "Referential #{referential.id} #{referential.metadatas.inspect} overlaps #{metadatas.inspect}"
      errors.add :metadatas, I18n.t("referentials.errors.overlapped_referential", :referential => referential.name)
    end
  end

  def create_from_current_offer
    pending!

    enqueue_job :fill_from_current_offer
  end

  # Create referential from current workbench output
  def fill_from_current_offer
    current_offer = workbench.output.current

    lines = metadatas_lines
    copy = ReferentialCopy.new source: current_offer, target: self, skip_metadatas: true, lines: lines
    copy.copy!

    active!
  end

  attr_accessor :inline_clone
  def clone_schema
    cloning = ReferentialCloning.new source_referential: created_from, target_referential: self

    if inline_clone
      cloning.clone!
    else
      cloning.save!
    end
  end

  def create_schema
    return if bare

    Chouette::Benchmark.measure("referential.create", referential: id) do
      schema.create
    end
  end

  def migration_count
    raw_value =
      if self.class.connection.table_exists?("#{slug}.schema_migrations")
        self.class.connection.select_value("select count(*) from \"#{slug}\".schema_migrations;")
      end

    raw_value.to_i
  end

  def assign_slug(time_reference = Time)
    self.slug ||= SecureRandom.uuid
  end

  def assign_prefix
    self.prefix ||= workbench.prefix if workbench
  end

  def assign_line_and_stop_area_referential
    self.line_referential = workbench.line_referential
    self.stop_area_referential = workbench.stop_area_referential
  end

  def destroy_schema
    return unless ActiveRecord::Base.connection.schema_names.include?(slug)
    Apartment::Tenant.drop slug
  end

  def schema
    @schema ||= ReferentialSchema.new slug
  end

  def destroy_jobs
    true
  end

  # Archive
  def archived?
    archived_at != nil
  end

  def archive!
    # self.archived = true
    touch :archived_at
    notify_state
  end
  def unarchive!
    return false unless can_unarchive?
    # self.archived = false
    update_column :archived_at, nil
    notify_state
  end

  def can_unarchive?
    not metadatas_overlap?
  end

  def merged?
    merged_at.present?
  end

  def self.not_merged
    where merged_at: nil
  end

  def self.mergeable
    editable
  end

  def self.editable
    active.not_merged.not_in_referential_suite
  end

  ### STATE

  def state
    return :failed if failed_at.present?
    return :archived if archived_at.present?
    return :pending unless ready?
    :active
  end

  def light_update vals
    if self.persisted?
      update_columns vals
    else
      assign_attributes vals
    end
    notify_state
  end

  def pending!
    light_update ready: false, failed_at: nil, archived_at: nil
  end

  def failed!
    light_update ready: false, failed_at: Time.now, archived_at: nil
  end

  def active!
    light_update ready: true, failed_at: nil, archived_at: nil, merged_at: nil
  end

  alias_method :rollbacked!, :active!

  def archived!
    light_update failed_at: nil, archived_at: Time.now
  end

  def merged!
    now = Time.now
    update_columns failed_at: nil, archived_at: now, merged_at: now, ready: true
    notify_state
  end

  def unmerged!
    # always change merged_at
    update_column :merged_at, nil
    # change archived_at if possible
    update archived_at: nil
  end

  STATES.each do |s|
    define_method "#{s}?" do
      state == s
    end
  end

  def pending_while
    if pending?
      yield
      return
    end

    vals = attributes.slice(*%w(ready archived_at failed_at))
    pending!
    begin
      yield
    ensure
      update vals
    end
  end

  def rebuild_cross_referential_index!
    CrossReferentialIndexEntry.rebuild_index_for_referential!(self)
  end

  def clean_cross_referential_index!
    CrossReferentialIndexEntry.clean_index_for_referential!(self)
  end

  private

  def lock_table
    # No explicit unlock is needed as it will be released at the end of the
    # transaction.
    ActiveRecord::Base.connection.execute(
      'LOCK public.referential_metadata IN SHARE ROW EXCLUSIVE MODE'
    )
  end
end
