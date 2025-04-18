# frozen_string_literal: true

class Publication < Operation
  belongs_to :publication_setup # CHOUETTE-3247 required: true
  has_one :export, class_name: 'Export::Base', dependent: :destroy
  belongs_to :referential # CHOUETTE-3247 required: true
  belongs_to :parent, polymorphic: true, optional: true # CHOUETTE-3247
  has_many :reports, class_name: 'DestinationReport', dependent: :destroy
  has_many :publication_api_sources, class_name: 'PublicationApiSource', dependent: :destroy

  has_one :workgroup, through: :publication_setup
  has_one :organisation, through: :workgroup, source: :owner

  def pretty_date
    I18n.l(created_at)
  end

  def name
    self.class.tmf('name', setup_name: publication_setup.name, date: pretty_date)
  end

  def perform # rubocop:disable Metrics/MethodLength
    referential.switch do
      export_builder.build_export.tap do |export|
        Rails.logger.info "Launching export #{export.name}"
        export.save!

        if export.synchronous && !export.successful?
          Rails.logger.error "Publication Export '#{export.name}' failed"
          return # rubocop:disable Lint/NonLocalExitFromIterator
        end
      end

      send_to_destinations
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

  class ExportStatus < Operation::Callback
    delegate :export, to: :operation

    def after
      return unless operation.error_uuid.present?
      return unless export
      return unless export.status.new? || export.status.pending? || export.status.running?

      export.failed!
    end
  end
  callback ExportStatus

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

    def cache_prefix
      publication_setup.cache_key_with_version if publication_setup.enable_cache
    end

    def export_attributes
      publication_export_options.merge(
        referential: referential,
        name: publication_name,
        creator: publication_name,
        synchronous: true,
        workgroup: workgroup,
        publication: publication,
        cache_prefix: cache_prefix
      )
    end
  end
end
