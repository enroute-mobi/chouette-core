class Merge < ApplicationModel
  include OperationSupport
  include NotifiableSupport

  belongs_to :workbench
  has_many :compliance_check_sets, -> { where(parent_type: 'Merge') }, foreign_key: :parent_id, dependent: :destroy
  has_many :processings, as: :operation
  has_many :macro_list_runs, through: :processings, :source => :processed, source_type: "Macro::List::Run"
  has_many :control_list_runs, through: :processings, :source => :processed, source_type: "Control::List::Run"

  delegate :output, to: :workbench
  delegate :workgroup, to: :workbench

  validates :workbench, presence: true

  EXPERIMENTAL_METHOD = 'experimental'
  enumerize :merge_method, in: ['legacy', EXPERIMENTAL_METHOD], default: 'legacy'

  def parent
    workbench
  end

  def is_current?
    new_id == workbench.output.current_id
  end

  def rollback!
    raise 'You cannot rollback to the current version' if current?

    workbench.output.update current: new
    following_merges.each(&:cancel!)
  end

  def cancel!
    super
    referentials.each(&:unmerged!)
    new&.rollbacked!
  end

  def following_merges
    following_referentials = workbench.output.referentials.where('created_at > ?', new.created_at)
    workbench.merges.where(new_id: following_referentials.pluck(:id))
  end

  def pending!
    super
    referentials.each(&:pending!)
  end

  def merge
    with_lock do
      # Step 1 : Before
      update_column :started_at, Time.now

      Rails.logger.info "Change Merge##{id} status to running"
      update_column :status, :running

      referentials.each(&:pending!)

      if processing_rules_before_merge.present?
        continue_after_processings = processor.before(referentials)
        # Check processed status and stop merge if one failed
        unless continue_after_processings
          referentials.each &:active!
          update status: :failed, ended_at: Time.now
          return
        end
      end  

      if before_merge_compliance_control_sets.present?
        create_before_merge_compliance_check_sets
      else
        enqueue_job :merge!
      end
    end
  end
  alias run merge

  

  def before_merge_compliance_control_sets
    workbench.workgroup.before_merge_compliance_control_sets.map do |key, _|
      cc_set = workbench.compliance_control_set(key)
      cc_set.present? ? [key, cc_set] : nil
    end.compact
  end

  def after_merge_compliance_control_sets
    workbench.workgroup.after_merge_compliance_control_sets.map do |key, _|
      cc_set = workbench.compliance_control_set(key)
      cc_set.present? ? [key, cc_set] : nil
    end.compact
  end

  def create_before_merge_compliance_check_sets
    referentials.each do |referential|
      before_merge_compliance_control_sets.each do |key, compliance_control_set|
        create_compliance_check_set key, compliance_control_set, referential
      end
    end
  end

  def create_after_merge_compliance_check_sets
    after_merge_compliance_control_sets.each do |key, compliance_control_set|
      create_compliance_check_set key, compliance_control_set, new
    end
  end

  def merge!
    Rails.logger.info "Start Merge##{id} merge for #{referential_ids}"

    CustomFieldsSupport.within_workgroup(workgroup) do
      Chouette::Benchmark.measure('merge', merge: id) do
        Chouette::Benchmark.measure('prepare_new') do
          prepare_new
        end

        referentials.each do |referential|
          Chouette::Benchmark.measure('referential', referential: referential.id) do
            merge_referential_method_class.new(self, referential).merge!
          end
        end

        Chouette::Benchmark.measure('clean_new') do
          clean_new
        end

        if processing_rules_after_merge.present?
          continue_after_processings = processor.after([new])
          # Check processed status and stop merge if one failed
          unless continue_after_processings
            referentials.each &:active!
            update status: :failed, ended_at: Time.now
            return
          end
        end
        
        if after_merge_compliance_control_sets.present?
          create_after_merge_compliance_check_sets
        else
          save_current
        end
      end
    end
  rescue StandardError => e
    Chouette::Safe.capture "Merge ##{id} failed", e
    raise e if Rails.env.test?

    failed!
  end

  def merge_referential_method_class
    if merge_method == EXPERIMENTAL_METHOD || SmartEnv.boolean('FORCE_MERGE_METHOD')
      Merge::Referential::Experimental
    else
      Merge::Referential::Legacy
    end
  end

  def prepare_new
    if Rails.env.test? && new.present?
      Rails.logger.debug 'Use existing new for test'
      return
    end

    new =
      if workbench.output.current
        Rails.logger.debug "Merge ##{id}: Clone current output"
        ::Referential.new_from(workbench.output.current, workbench).tap do |clone|
          clone.inline_clone = true
        end
      else
        if workbench.merges.successful.count > 0
          # there had been previous merges, we should have a current output
          raise "Trying to create a new referential to merge into from Merge##{id}, while there had been previous merges in the same workbench"
        end

        Rails.logger.debug "Merge ##{id}: Create a new output"
        # 'empty' one
        attributes = {
          workbench: workbench,
          organisation: workbench.organisation # TODO: could be workbench.organisation by default
        }
        workbench.output.referentials.new attributes
      end

    new.referential_suite = output
    new.workbench = workbench
    new.organisation = workbench.organisation
    new.name = I18n.t('merges.referential_name', date: I18n.l(created_at, format: :short_with_time))

    Rails.logger.error "Merge ##{id}: New referential isn't valid : #{new.errors.inspect}" unless new.valid?

    begin
      new.save!
    rescue StandardError
      Rails.logger.debug "Merge ##{id}: Errors on new referential: #{new.errors.messages}"
      raise
    end

    new.metadatas.reload
    new.flag_not_urgent!
    new.pending!

    output.update new: new
    update new: new
  end

  def clean_new
    clean_up_options = {
      referential: new,
      clean_methods: %i[clean_irrelevant_data clean_unassociated_calendars]
    }
    clean_scope = Clean::Scope::Referential.new(new)

    if workgroup.enable_purge_merged_data
      last_date = Time.zone.today - [workgroup.maximum_data_age, 0].max
      Clean::Metadata::Before.new(clean_scope, last_date - 1).clean!

      clean_up_options.merge!({ date_type: :before, begin_date: last_date })
    end

    Clean::Timetable::Date::ExcludedWithoutPeriod.new(clean_scope).clean!
    CleanUp.new(clean_up_options).clean
    Clean::Timetable::Date::ExcludedWithoutPeriod.new(clean_scope).clean!
  end

  def after_save_current
    referentials.each(&:merged!)
    Stat::JourneyPatternCoursesByDate.compute_for_referential(new, line_ids: merged_line_ids)
    aggregate_if_urgent_offer
    HoleSentinel.new(workbench).watch!
  end

  def merged_line_ids
    referentials.map { |r| r.metadatas_lines.map(&:id) }.flatten.uniq
  end

  alias line_ids merged_line_ids

  def aggregate_if_urgent_offer
    workbench.workgroup.aggregate_urgent_data! if new&.contains_urgent_offer?
  end

  def clean_scope
    scope = parent.merges
    if parent.locked_referential_to_aggregate_id.present?
      scope = scope.where("new_id IS NULL OR new_id != #{parent.locked_referential_to_aggregate_id}")
    end

    aggregated_referentials = parent.workgroup.aggregates.flat_map(&:referential_ids).compact.uniq
    scope = scope.where.not(new_id: aggregated_referentials) if aggregated_referentials.present?

    scope
  end

  def concurent_operations
    parent.merges.where.not(id: id)
  end

  def processor
    @processor ||= Processor.new(self)
  end

  def processing_rules_before_merge
    workbench_processing_rules_before_merge + workgroup_processing_rules_before_merge
  end

  def workbench_processing_rules_before_merge
    workbench.processing_rules.where(operation_step: 'before_merge').order(processable_type: :desc)
  end

  def workgroup_processing_rules_before_merge
    dedicated_processing_rules = workbench.workgroup.processing_rules.where(operation_step: 'before_merge').with_target_workbenches_containing(workbench_id)
    return dedicated_processing_rules if dedicated_processing_rules.present?

    workbench.workgroup.processing_rules.where(operation_step: 'before_merge', target_workbench_ids: [])
  end

  def processing_rules_after_merge
    workbench_processing_rules_after_merge + workgroup_processing_rules_after_merge
  end

  def workbench_processing_rules_after_merge
    workbench.processing_rules.where(operation_step: 'after_merge').order(processable_type: :desc)
  end

  def workgroup_processing_rules_after_merge
    dedicated_processing_rules = workbench.workgroup.processing_rules.where(operation_step: 'after_merge').with_target_workbenches_containing(workbench_id)
    return dedicated_processing_rules if dedicated_processing_rules.present?

    workbench.workgroup.processing_rules.where(operation_step: 'after_merge', target_workbench_ids: [])
  end
end
