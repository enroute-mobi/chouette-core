# frozen_string_literal: true

RSpec.describe ProcessingRule::Scheduling, type: :model do
  let(:context) do
    Chouette.create do
      workbench do
        control_list
        workbench_processing_rule operation_step: 'after_import'
      end
    end
  end
  let(:workbench) { context.workbench }
  let(:processing_rule) { context.workbench_processing_rule }

  let(:scheduled_days) { Cuckoo::DaysOfWeek.all }
  let(:target) { 'none' }
  let(:scheduling) do
    processing_rule.schedulings.create!(
      scheduled_days: scheduled_days,
      target: target
    )
  end

  it { is_expected.to belong_to(:processing_rule).required }

  it { is_expected.to allow_value(Cuckoo::DaysOfWeek.all).for(:scheduled_days) }
  it { is_expected.to allow_value(Cuckoo::DaysOfWeek.new(monday: true, tuesday: true)).for(:scheduled_days) }
  it { is_expected.not_to allow_value(Cuckoo::DaysOfWeek.none).for(:scheduled_days) }

  it { is_expected.to enumerize(:target).in('none', 'current', 'merged').with_default('none') }

  describe '#target' do
    subject(:scheduling) do
      processing_rule.schedulings.build(scheduled_days: scheduled_days, target: target)
    end

    context "with a Workbench Processing Rule ('merged' is Workgroup specific)" do
      %w[none current].each do |candidate_target|
        context "when target is #{candidate_target}" do
          let(:target) { candidate_target }

          it { is_expected.to be_valid }
        end
      end

      context "when target is 'merged'" do
        let(:target) { 'merged' }

        it 'is invalid' do
          expect(scheduling).not_to be_valid
          expect(scheduling.errors).to be_added(:target, :inclusion)
        end
      end
    end

    context 'with a Workgroup Processing Rule' do
      let(:context) do
        Chouette.create do
          workgroup do
            workbench do
              control_list shared: true
            end
            workgroup_processing_rule operation_step: 'scheduling'
          end
        end
      end
      let(:processing_rule) { context.workgroup_processing_rule }

      context "when target is 'merged'" do
        let(:target) { 'merged' }

        it { is_expected.to be_valid }
      end
    end
  end

  describe 'scheduled_days' do
    subject { scheduling.scheduled_days }

    it { is_expected.to be_a(Cuckoo::DaysOfWeek) }
  end

  describe '#scheduled_job' do
    subject(:scheduled_job) { scheduling.scheduled_job }

    it do
      expect(scheduled_job).to have_attributes(
        handler: match(/ProcessingRule::Scheduling::ScheduledJob/),
        cron: '0 0 * * *'
      )
    end

    it 'does not serialize the whole scheduling' do
      expect(scheduled_job.handler).not_to include('scheduling: !ruby/object:ProcessingRule::Scheduling')
      expect(scheduled_job.payload_object.scheduling).to eq(scheduling)
    end

    context '#next_schedule' do
      subject { scheduling.next_schedule }

      it { is_expected.to be_present }
    end

    context '#reschedule' do
      subject { scheduling.reschedule }

      it { expect { subject }.not_to(change { scheduled_job.reload.attributes }) }

      context 'when scheduled job has wrong attributes' do
        before { scheduled_job.update(cron: '1 2 3 4 5') }

        it do
          expect { subject }.to(
            change { scheduled_job.reload.cron }.and(change { scheduled_job.reload.run_at })
          )
        end
      end
    end

    context 'when #scheduled_time changes' do
      subject { scheduling.update(scheduled_time: TimeOfDay.new('12', '20')) }

      it do
        expect { subject }.to(
          change { scheduled_job.reload.cron }.to('20 12 * * *').and(change { scheduled_job.reload.run_at })
        )
      end
    end

    context 'when #scheduled_days changes' do
      subject do
        scheduling.update(scheduled_days: Cuckoo::DaysOfWeek.new(monday: true, tuesday: true))
      end

      it { expect { subject }.to change { scheduled_job.reload.cron }.to('0 0 * * 1,2') }
    end

    context 'when scheduling is destroyed' do
      before { scheduling.destroy }

      it { expect { scheduled_job.reload }.to raise_error(ActiveRecord::RecordNotFound) }
    end

    context 'if scheduled job is destroyed' do
      before do
        job = scheduled_job
        scheduling.update_column(:scheduled_job_id, nil)
        job.destroy
      end

      context '#next_schedule' do
        subject { scheduling.next_schedule }

        it { is_expected.to eq(nil) }
      end

      context '#reschedule' do
        subject { scheduling.reschedule }

        it do
          expect { subject }.to change { scheduling.scheduled_job }.from(nil).to(
            have_attributes(handler: match(/ProcessingRule::Scheduling::ScheduledJob/))
          )
        end
      end
    end
  end

  describe ProcessingRule::Scheduling::ScheduledJob do
    subject(:job) { described_class.new(scheduling) }

    describe '#cron' do
      subject { job.cron }

      it { is_expected.to eq('0 0 * * *') }
    end

    describe '#perform' do
      subject { job.perform }

      context 'when target is none' do
        it 'performs the processing rule without referential' do
          expect(scheduling.processing_rule).to receive(:perform).with(
            referential: nil,
            operation_workbench: workbench
          )
          subject
        end
      end

      context 'when target is current' do
        let(:target) { 'current' }
        let(:referential) { double('referential') }

        before do
          allow(scheduling.processing_rule).to receive(:output_current_referential).and_return(referential)
        end

        it 'performs the processing rule on the output current referential' do
          expect(scheduling.processing_rule).to receive(:perform).with(
            referential: referential,
            operation_workbench: workbench
          )
          subject
        end
      end
    end
  end
end
