class Aggregate < ApplicationModel
  DEFAULT_KEEP_AGGREGATES = 10

  include OperationSupport
  include NotifiableSupport

  belongs_to :workgroup
  has_many :compliance_check_sets, -> { where(parent_type: "Aggregate") }, foreign_key: :parent_id, dependent: :destroy

  validates :workgroup, presence: true

  after_commit :aggregate, on: :create, unless: :profile?

  delegate :output, to: :workgroup

  def parent
    workgroup
  end

  def self.profile(referentials=nil, profile_options={})
    referentials ||= [Workgroup.first.output.current]
    referentials.compact!

    raise 'Missing referential' unless referentials.present?

    aggregate = self.new(referentials: referentials, workgroup: Workgroup.first)
    aggregate.profile = true
    aggregate.profile_options = profile_options
    aggregate.name = "Aggregate profile #{Time.now}"

    aggregate.save!

    aggregate.profile_tag 'aggregate!' do
      aggregate.aggregate!
    end

    pp aggregate.profile_stats
    aggregate
  end

  def rollback!
    raise "You cannot rollback to the current version" if current?
    workgroup.output.update current: self.new
    following_aggregates.each(&:cancel!)
    publish
    workgroup.aggregated!
  end

  def cancel!
    update status: :canceled
    new.rollbacked!
  end

  def following_aggregates
    following_referentials = workgroup.output.referentials.where('created_at > ?', new.created_at)
    workgroup.aggregates.where(new_id: following_referentials.pluck(:id))
  end

  def aggregate
    update_column :started_at, Time.now
    update_column :status, :running

    enqueue_job :aggregate!
  end

  def aggregate!
    prepare_new

    profile_tag 'copy_data' do
      referentials.each do |source|
        ReferentialCopy.new(source: source, target: new, profiler: self).copy!
      end
    end

    if after_aggregate_compliance_control_set.present?
      create_after_aggregate_compliance_check_set
    else
      save_current
    end
  rescue => e
    Rails.logger.error "Aggregate failed: #{e} #{e.backtrace.join("\n")}"
    failed!
    raise e if Rails.env.test?
  end

  def workbench_for_notifications
    workgroup.owner_workbench
  end

  def self.keep_operations
    @keep_operations ||= begin
      if Rails.configuration.respond_to?(:keep_aggregates)
        Rails.configuration.keep_aggregates
      else
        DEFAULT_KEEP_AGGREGATES
      end
    end
  end

  def after_save_current
    clean_previous_operations
    publish
    workgroup.aggregated!
  end

  private

  def prepare_new
    profile_tag 'prepare_new!' do
      Rails.logger.debug "Create a new output"
      # 'empty' one
      attributes = {
        organisation: workgroup.owner,
        prefix: "aggregate_#{id}",
        line_referential: workgroup.line_referential,
        stop_area_referential: workgroup.stop_area_referential,
        objectid_format: referentials.first.objectid_format,
        # TODO Fix this (cf CHOUETTE-283)
        workbench: nil
      }
      new = workgroup.output.referentials.new attributes
      new.referential_suite = output
      new.slug = "output_#{workgroup.id}_#{created_at.to_i}"
      new.name = I18n.t("aggregates.referential_name", date: I18n.l(created_at, format: :short_with_time))

      unless new.valid?
        Rails.logger.error "New referential isn't valid : #{new.errors.inspect}"
      end

      begin
        new.save!
      rescue
        Rails.logger.debug "Errors on new referential: #{new.errors.messages}"
        raise
      end

      new.pending!

      output.update new: new
      update new: new
    end
  end

  def after_aggregate_compliance_control_set
    @after_aggregate_compliance_control_set ||= workgroup.compliance_control_set(:after_aggregate)
  end

  def create_after_aggregate_compliance_check_set
    create_compliance_check_set :after_aggregate, after_aggregate_compliance_control_set, new
  end
end

#STI
require_dependency 'aggregates/nightly_aggregate'
