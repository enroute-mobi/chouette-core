require 'net/http'
class Import::Netex < Import::Base
  include ImportResourcesSupport

  before_destroy :destroy_non_ready_referential

  after_commit :update_main_resource_status, on:  [:create, :update]

  before_save do
    self.referential&.failed! if self.status == 'aborted' || self.status == 'failed'
  end

  validates_presence_of :parent

  def self.accepts_file?(file)
    Zip::File.open(file) do |zip_file|
      zip_file.glob('**/calendriers.xml').size >= 1
    end
  rescue => e
    Chouette::Safe.capture "Error in testing NeTEx file: #{file}", e
    return false
  end

  def main_resource
    @resource ||= parent.resources.find_or_create_by(name: self.name, resource_type: "referential", reference: self.name)
  end

  def notify_parent
    return false unless finished?
    return false unless parent.present?
    return false if notified_parent_at

    # Update notified_parent_at for Api::V1::Internals::NetexImportsController
    update_column :notified_parent_at, Time.now

    Rails.logger.info "#{self.class.name} ##{id}: notify_parent"
    # CHOUETTE-3078 Hack to avoid iev control and multiple parsing the same file calendriers.xml
    # Find duplicated periods for each timetable
    time_tables = time_tables_with_duplicated_periods
    # Create messages for netex import
    time_tables.find_each do |time_table|
      main_resource.messages.create(criticity: :error, message_attributes: { timetable_objectid: time_table.objectid }, message_key: 'overlaping_period_for_timetable')
    end
    # Override status for netex import
    failed! if time_tables.present?

    # Do nothing : update main resource status never displayed
    main_resource.update_status_from_importer self.status
    update_referential

    # Launch Control::List or Macro::List asynchronously
    Rails.logger.info "#{self.class.name} ##{id}: invoke async_processable"
    processor.after([referential])

    parent&.child_change

    true
  end

  def time_tables_with_duplicated_periods
    return unless referential.present?

    referential.switch
    periods = referential.time_table_periods.overlapping_siblings
    referential.time_tables.where(id: periods.select(:time_table_id).distinct)
  end

  def processor
    @processor ||= Processor.new(self)
  end

  def line_ids
    referential_metadata.line_ids
  end

  private

  def update_referential
    if self.status.successful? || self.status.warning?
      self.referential&.active!
    else
      self.referential&.failed!
    end
  end

  def iev_callback_url
    URI("#{Rails.configuration.iev_url}/boiv_iev/referentials/importer/new?id=#{id}")
  end

  def destroy_non_ready_referential
    if referential && !referential.ready
      referential.destroy
    end
  end

  def referential_metadata
    metadata = ReferentialMetadata.new

    if self.file && self.file.path
      file.cache_stored_file!
      netex_file = STIF::NetexFile.new(self.file.path)
      frame = netex_file.frames.first

      if frame
        metadata.periodes = frame.periods

        @line_objectids = frame.line_refs.map { |ref| "FR1:Line:#{ref}:" }
        metadata.line_ids = workbench.lines.where(objectid: @line_objectids).pluck(:id)
      end
    end

    metadata
  end
end
