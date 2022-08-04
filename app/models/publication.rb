class Publication < ApplicationModel
  extend Enumerize

  enumerize :status, in: %w[new pending successful failed running successful_with_warnings], default: :new

  belongs_to :publication_setup
  has_many :exports, class_name: 'Export::Base', dependent: :destroy
  belongs_to :parent, polymorphic: true
  has_many :reports, class_name: 'DestinationReport', dependent: :destroy
  has_many :publication_api_sources, class_name: 'PublicationApiSource', dependent: :destroy

  validates :publication_setup, :parent, presence: true

  after_commit :publish, on: :create

  status.values.each do |s|
    define_method "#{s}!" do
      update status: s
    end

    define_method "#{s}?" do
      status.to_s == s
    end
  end

  def running!
    update_columns status: :running, started_at: Time.now
  end

  delegate :workgroup, to: :publication_setup

  %i[failed successful successful_with_warnings].each do |s|
    define_method "#{s}!" do
      update status: s, ended_at: Time.now
    end
  end

  def publish
    return unless new?
    pending!
    enqueue_job :run
  end

  def pretty_date
    I18n.l(created_at)
  end

  def name
    self.class.tmf('name', setup_name: publication_setup.name, date: pretty_date)
  end

  def run
    running!
    run_export
  rescue => e
    Chouette::Safe.capture "Publication ##{id} failed", e
    failed!
  end

  def referential
    parent.new
  end

  def run_export
    referential.switch do
      all_synchronous = true

      exports_builder.exports.each do |export|
        all_synchronous = all_synchronous && export.synchronous
        begin
          Rails.logger.info "Launching export #{export.name}"
          export.save!
        rescue => e
          Chouette::Safe.capture "Publication Export ##{export.id} failed", e
          failed!
          return
        end

        if export.synchronous && !export.successful?
          Rails.logger.error "Publication Export '#{export.name}' failed"
          failed!
          return
        end
      end

      return unless all_synchronous

      send_to_destinations
      infer_status
    end
  end

  def send_to_destinations
    publication_setup.destinations.each { |destination| destination.transmit(self) }
  end

  def child_change
    Rails.logger.info "child_change for #{inspect}"

    if exports.all?(&:finished?) && running?
      send_to_destinations
      infer_status
    end
  end

  def infer_status
    failed! && return unless exports.all?(&:successful?)

    new_status = reports.all?(&:successful?) ? :successful : :successful_with_warnings
    send("#{new_status}!")
  end

  def export_output
    export&.file
  end

  def previous
    publication_setup.publications.order(created_at: :desc).where.not(id: self).first
  end

  def publish_per_line?
    publication_setup.publish_per_line
  end

  def exports_builder_class
    publish_per_line? ? ExportBuilder::PerLine : ExportBuilder::Full
  end

  def exports_builder
    exports_builder_class.new(self)
  end

  # Manage the creation of Export or Exports for the Publication
  module ExportBuilder
    class Base
      def initialize(publication)
        @publication = publication
      end

      attr_reader :publication
      delegate :referential, :workgroup, :publication_setup, to: :publication

      def build_export(line: nil)
        attributes = export_attributes

        if line
          attributes[:name] = "#{attributes[:name]} - #{Chouette::Line.model_name.human} #{line.name}"
          attributes[:line_ids] = [ line.id ]
        end

        publication.exports.build(attributes)
      end

      def publication_export_options
        publication_setup.export_options
      end

      def publication_name
        "#{Publication.model_name.human} #{publication.name}"
      end

      def export_attributes
        publication_export_options.merge(
          referential: referential,
          name: publication_name,
          creator: publication_name,
          synchronous: true,
          workgroup: workgroup
        )
      end
    end

    class Full < Base
      def exports
        [ build_export ]
      end
    end

    class PerLine < Base
      def exports
        published_lines.map do |line|
          freshness_attributes = {}
          unless rollback?
            freshness_attributes[:updated_at] = lines_status.updated_at(line)
            freshness_attributes[:published_at] = publication_timestamps[line.id]
          end

          PublishedLine.new(self, line, freshness_attributes).export
        end.compact
      end

      delegate :rollback?, to: :publication

      def export_scope
        @export_scope ||= Export::Scope::Options.new(referential, publication_setup.export_scope_options).scope
      end

      def published_lines
        export_scope.lines
      end

      def lines_status
        @lines_status ||= publication.referential.lines_status
      end

      def publication_timestamps
        @publication_timestamps ||=
          begin
            # We need to use a subquery because Rails (5) fails to group.maximum on "virtual" column line_id created by select expression
            query = "select line_id, max(created_at) from (#{publication_setup.exports.select("json_array_elements_text((options->'line_ids')::json)::int as line_id", :created_at).to_sql}) as s group by line_id"
            database_timezone ||= Time.find_zone("UTC")

            ActiveRecord::Base.connection.select_rows(query).map do |line_id, time|
              [ line_id, database_timezone.parse(time) ]
            end.to_h
          end
      end

      class PublishedLine
        def initialize(builder, line, attributes = {})
          @builder, @line = builder, line
          attributes.each { |k,v| send "#{k}=", v }
        end
        attr_reader :line, :builder
        attr_accessor :published_at, :updated_at

        delegate :publication, :build_export, to: :builder

        def stale?
          updated_at.nil? || published_at.nil? || updated_at > published_at
        end

        def export
          unless stale?
            Rails.logger.info "Skip export for Line ##{line.id} for Publication ##{publication.id} (updated_at: #{updated_at}, published_at: #{published_at})"
            return
          end

          build_export line: line
        end
      end
    end
  end
end
