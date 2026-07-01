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

  describe '#target_referential' do
    subject { scheduling.target_referential }

    context 'when target is none' do
      let(:target) { 'none' }

      it { is_expected.to be_nil }
    end

    context 'when target is current' do
      let(:target) { 'current' }
      let(:referential) { double('referential') }

      before { allow(scheduling.processing_rule).to receive(:output_current_referential).and_return(referential) }

      it 'returns the processing rule output current referential' do
        is_expected.to eq(referential)
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

      it 'performs the processing rule with the selected target and workbench' do
        expect(scheduling.processing_rule).to receive(:perform).with(
          referential: scheduling.target_referential,
          operation_workbench: workbench
        )
        subject
      end
    end
  end
end
