class Export::Workgroup < Export::Base
  after_commit :launch_worker, :on => :create

  option :duration, required: true, type: :integer, default_value: 90

  def launch_worker
    enqueue_job :export!
  end

  def export!
    @entries = 0
    update(status: 'running', started_at: Time.now)
    create_sub_jobs
  rescue Exception => e
    logger.error e.message
    update( status: 'failed' )
    raise
  end

  private
  def create_sub_jobs
    # XXX TO DO
    workbench.workgroup.referentials.each do |ref|
      ref.lines.each do |line|
        netex_export = Export::Netex.new
        netex_export.name = "Export line #{line.name} of Referential #{ref.name}"
        netex_export.workbench = workbench
        netex_export.creator = creator
        netex_export.export_type = :line
        netex_export.referential = referential
        netex_export.duration = duration
        netex_export.line_code = line.objectid
        netex_export.parent = self
        netex_export.save!
      end
    end
  end
end
