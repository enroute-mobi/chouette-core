# frozen_string_literal: true

class Publication < Operation
  belongs_to :publication_setup
  has_one :export, class_name: 'Export::Base', dependent: :destroy
  belongs_to :parent, polymorphic: true
  has_many :reports, class_name: 'DestinationReport', dependent: :destroy
  has_many :publication_api_sources, class_name: 'PublicationApiSource', dependent: :destroy

  validates :publication_setup, :parent, presence: true

  has_one :workgroup, through: :publication_setup
  has_one :organisation, through: :workgroup, source: :owner

  def pretty_date
    I18n.l(created_at)
  end

  def name
    self.class.tmf('name', setup_name: publication_setup.name, date: pretty_date)
  end

  def referential
    parent.new
  end

  def perform
    referential.switch do
      all_synchronous = true

      export_builder.build_export.tap do |export|
        all_synchronous = all_synchronous && export.synchronous

        Rails.logger.info "Launching export #{export.name}"
        export.save!

        raise "Publication Export '#{export.name}' failed" if export.synchronous && !export.successful?
      end

      return unless all_synchronous

      send_to_destinations
      # Send notification for synchronous exports (Publication Netex Generic, GTFS...)
      workbench = workgroup.owner_workbench
      workbench.notification_center.notify(self) if workbench
    end
  end

  def send_to_destinations
    publication_setup.destinations.each { |destination| destination.transmit(self) }
  end

  def final_user_status
    if export.successful?
      reports.all?(&:successful?) ? Operation.user_status.successful : Operation.user_status.warning
    else
      Operation.user_status.failed
    end
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
