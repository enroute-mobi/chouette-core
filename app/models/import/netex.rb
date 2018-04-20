require 'net/http'
class Import::Netex < Import::Base
  before_destroy :destroy_non_ready_referential

  after_commit :call_iev_callback, on: :create

  before_save do
    self.status = 'aborted' unless referential
    self.referential&.failed! if self.status == 'aborted' || self.status == 'failed'
  end

  validates_presence_of :parent

  def create_with_referential!
    self.referential =
      Referential.new(
        name: self.name,
        organisation_id: workbench.organisation_id,
        workbench_id: workbench.id,
        metadatas: [referential_metadata]
      )
    self.referential.save
    if self.referential.invalid?
      Rails.logger.info "Can't create referential for import #{self.id}: #{referential.inspect} #{referential.metadatas.inspect} #{referential.errors.messages}"
      if referential.metadatas.all?{|m| m.line_ids.present? && m.line_ids.empty?}
        parent.messages.create criticity: :error, message_key: "referential_creation_missing_lines", message_attributes: {referential_name: referential.name}
      else
        parent.messages.create criticity: :error, message_key: "referential_creation", message_attributes: {referential_name: referential.name}
      end
    else
      save!
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
        metadata.line_ids = workbench.lines.where(objectid: line_objectids).pluck(:id)
      end
    end

    metadata
  end
end
