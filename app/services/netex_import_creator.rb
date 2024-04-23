# Manage the (too complex) Netex Import creation
#
# * Create the Import::Netex instance with the given attributes
# * Analyse the NeTEx file find the covered periods and lines
# * Validate everything is fine .. or abort
#
# Then start a Job to
# * Create the required Referential (which can be too long as CHOUETTE-769)
# * Invoke the IEV callback
#
# To create a job in correct conditions, the class saves only the required attributes (see #encode_with)
class NetexImportCreator
  include Measurable
  attr_reader :attributes, :file

  def initialize(workbench, attributes = {})
    @workbench = workbench

    # File will be analysed
    @file = attributes[:file]

    @attributes = attributes
  end

  def import
    @import ||=
      if attributes
        Import::Netex.create(attributes) do |import|
          import.creator = import.parent&.creator || "Webservice"
        end
      else
        # Reload import after serialization
        workbench.imports.find @import_id
      end
  end

  # Reload workbench after serialization
  def workbench
    @workbench ||= Workbench.find(@workbench_id)
  end

  def create
    Rails.logger.debug "Create Import::Netex for #{attributes.inspect}"

    measure 'import_netex_creator.create' do
      if valid?
        enqueue_job
      else
        abort
      end

      self
    end
  end

  def valid?
    unless import.valid?
      return false
    end

    if netex_line_objectids.blank?
      create_message "referential_creation_missing_lines_in_files", referential_name: referential_name
      return false
    end

    if lines.blank?
      create_message "referential_creation_missing_lines", referential_name: referential_name
      return false
    end

    true
  end

  def start
    measure 'import_netex_creator.start', import_id: import.id do
      if init_referential
        import.call_iev_callback
        @started = true
      else
        abort
      end
    end
  end

  def started?
    @started
  end

  def referential_name
    import.name
  end

  def referential
    @referential ||= workbench.referentials.create(
      name: referential_name,
      organisation_id: workbench.organisation_id,
      metadatas: [referential_metadata],
      ready: false
    )
  end

  def init_referential
    Referential.transaction do
      if referential.valid?
        import.referential = referential
        import.main_resource.update referential: referential
        import.save!

        return true
      end

      # Create error messages associated to this invalid Referential
      overlapped_referential_ids = referential.overlapped_referential_ids
      if overlapped_referential_ids.any?
        overlapped = Referential.find overlapped_referential_ids.last
        create_message(
          "referential_creation_overlapping_existing_referential",
          referential_name: referential.name,
          overlapped_name: overlapped.name,
          overlapped_url:  Rails.application.routes.url_helpers.workbench_referential_path(workbench, overlapped)
        )
      else
        create_message(
          "referential_creation",
          { referential_name: referential.name },
          { resource_attributes: referential.errors.messages }
        )
      end

      false
    end
  end
  measure :init_referential

  def abort
    Rails.logger.debug "Abort Import #{import.inspect} #{import.errors.inspect}"
    return unless import.valid?

    # Usefull ?
    import.main_resource&.save

    import.aborted!
  end

  def netex_file
    @netex_file ||=
      begin
        STIF::NetexFile.new file.path
      end
  end
  measure :netex_file

  def netex_frame
    @netex_frame ||= netex_file.frames.first
  end

  def netex_periods
    @netex_periods ||= netex_frame&.periods
  end

  def netex_line_objectids
    @netex_line_objectids ||=
      (netex_frame.line_refs.map { |ref| "FR1:Line:#{ref}:" } if netex_frame)
  end

  def lines
    workbench.lines.where(objectid: netex_line_objectids)
  end

  def referential_metadata
    metadata = ReferentialMetadata.new

    metadata.periodes = netex_periods
    metadata.line_ids = lines.pluck(:id)

    metadata
  end

  def create_message(key, attributes = {}, resource_attributes = {})
    import.create_message criticity: :error, message_key: key, message_attributes: attributes, resource_attributes: resource_attributes
  end

  def enqueue_job
    if inline_job
      start
      return
    end

    job = LegacyOperationJob.new(self, :start)
    Rails.logger.info "Enqueue Operation #{job.display_name}"
    Delayed::Job.enqueue job
    job
  end
  attr_accessor :inline_job

  # Set to true to avoid job creation
  attr_accessor :inline

  # Save (in YAML) only minimalist attributes
  def encode_with(coder)
    coder['workbench_id'] = @workbench_id || workbench.id
    coder['import_id'] = @import_id || import.id
    coder['netex_periods'] = netex_periods
    coder['netex_line_objectids'] = netex_line_objectids
  end

  def to_json(*_)
    status =
      if started?
        {
          status: "ok",
          message:"Import ##{import.id} created as child of #{import.parent_type} (id: #{import.parent_id})"
        }
      else
        { status: "failed", message:"Import can't be created" }
      end
    status.to_json
  end

end
