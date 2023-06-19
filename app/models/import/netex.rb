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

    Rails.logger.info "#{self.class.name} ##{id}: notify_parent"
    main_resource.update_status_from_importer self.status
    update_referential

    # Launch Control::List or Macro::List asynchronously
    async_processable

    Rails.logger.info "#{self.class.name} ##{id}: invoke next_step"
    next_step

    super
  end

  def async_processable
    enqueue_job processor.after([referential])
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
