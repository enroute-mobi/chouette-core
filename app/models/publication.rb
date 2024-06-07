class Publication < ApplicationModel
  extend Enumerize

  enumerize :status, in: %w[new pending successful failed running successful_with_warnings], default: :new

  belongs_to :publication_setup
  has_one :export, class_name: 'Export::Base', dependent: :destroy
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

  has_one :workgroup, through: :publication_setup
  has_one :organisation, through: :workgroup, source: :owner

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
    raise 'Publication ran twice' if running?

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

      export_builder.build_export.tap do |export|
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
      # Send notification for synchronous exports (Publication Netex Generic, GTFS...)
      workbench = workgroup.owner_workbench
      workbench.notification_center.notify(self) if workbench
    end
  end

  def send_to_destinations
    publication_setup.destinations.each { |destination| destination.transmit(self) }
  end

  def infer_status
    failed! && return unless export.successful?

    new_status = reports.all?(&:successful?) ? :successful : :successful_with_warnings
    send("#{new_status}!")
  end

  def previous
    publication_setup.publications.order(created_at: :desc).where.not(id: self).first
  end

  def export_builder
    ExportBuilder.new(self)
  end

  # Manage the creation of Export or Exports for the Publication
  class ExportBuilder
    def initialize(publication)
      @publication = publication
    end

    attr_reader :publication
    delegate :referential, :workgroup, :publication_setup, to: :publication

    def build_export
      ::Export::Base.new(export_attributes)
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
        workgroup: workgroup,
        publication: publication
      )
    end
  end
end
