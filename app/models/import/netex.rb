require 'net/http'
class Import::Netex < Import::Base
  before_destroy :destroy_non_ready_referential

  after_commit do
    main_resource.update_status_from_importer self.status
    true
  end

  before_save do
    self.referential&.failed! if self.status == 'aborted' || self.status == 'failed'
  end

  validates_presence_of :parent

  def main_resource
    @resource ||= parent.resources.find_or_create_by(name: self.name, resource_type: "referential", reference: self.name)
  end

  def notify_parent
    if super
      main_resource.update_status_from_importer self.status
      next_step
    end
  end

  def next_step
    main_resource.next_step
  end

  def create_message args
    main_resource.messages.create args
  end

  def create_with_referential!
    save unless persisted?

    self.referential =
      Referential.new(
        name: self.name,
        organisation_id: workbench.organisation_id,
        workbench_id: workbench.id,
        metadatas: [referential_metadata]
      )
    self.referential.save

    if self.referential.valid?
      main_resource.update referential: referential
      call_iev_callback
      save!
    else
      Rails.logger.info "Can't create referential for import #{self.id}: #{referential.inspect} #{referential.metadatas.inspect} #{referential.errors.messages}"

      if referential.metadatas.all?{|m| m.line_ids.empty? && m.line_ids.empty?}
        create_message criticity: :error, message_key: "referential_creation_missing_lines", message_attributes: {referential_name: referential.name}
      elsif (overlapped_referential_ids = referential.overlapped_referential_ids).any?
        overlapped = Referential.find overlapped_referential_ids.last
        create_message(
          criticity: :error,
          message_key: "referential_creation_overlapping_existing_referential",
          message_attributes: {
            referential_name: referential.name,
            overlapped_name: overlapped.name,
            overlapped_url:  Rails.application.routes.url_helpers.referential_path(overlapped)
          }
        )
      else
        create_message(
          criticity: :error,
          message_key: "referential_creation",
          message_attributes: {referential_name: referential.name},
          resource_attributes: referential.errors.messages
        )
      end
      self.referential = nil
      aborted!
    end
  end

  private

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
      netex_file = STIF::NetexFile.new(self.file.path)
      frame = netex_file.frames.first

      if frame
        metadata.periodes = frame.periods

        line_objectids = frame.line_refs.map { |ref| "STIF:CODIFLIGNE:Line:#{ref}" }
        create_message criticity: :info, message_key: "referential_creation_lines_found", message_attributes: {line_objectids: line_objectids.to_sentence}
        metadata.line_ids = workbench.lines.where(objectid: line_objectids).pluck(:id)
      end
    end

    metadata
  end
end
