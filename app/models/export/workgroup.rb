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
    Chouette::Safe.capture "Export::Workgroup ##{id} failed", e
    update( status: 'failed' )
    raise
  end

  private
  def create_sub_jobs
    # XXX TO DO
    workbench.workgroup.referentials.each do |ref|
      ref.lines.each do |line|
        Export::Netex.create!(
          name: "Export line #{line.name} of Referential #{ref.name}",
          workbench: workbench,
          workgroup: workgroup,
          creator: creator,
          export_type: :line,
          referential: referential,
          duration: duration,
          line_code: line.objectid,
          parent: self
        )
      end
    end
  end
end
