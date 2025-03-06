# frozen_string_literal: true

RSpec.describe AggregateScheduling, type: :model do
  let(:context) { Chouette.create { workgroup } }
  let(:workgroup) { context.workgroup }

  let(:aggregate_days) { Cuckoo::DaysOfWeek.all }
  let(:force_daily_publishing) { true }
  let(:aggregate_scheduling) do
    workgroup.aggregate_schedulings.create!(
      aggregate_days: aggregate_days,
      force_daily_publishing: force_daily_publishing
    )
  end

  it { is_expected.to belong_to(:workgroup).required }

  it { is_expected.to allow_value(Cuckoo::DaysOfWeek.all).for(:aggregate_days) }
  it { is_expected.to allow_value(Cuckoo::DaysOfWeek.new(monday: true, tuesday: true)).for(:aggregate_days) }
  it { is_expected.not_to allow_value(Cuckoo::DaysOfWeek.none).for(:aggregate_days) }

  it { is_expected.to allow_value(true).for(:force_daily_publishing) }
  it { is_expected.to allow_value(false).for(:force_daily_publishing) }
  it { is_expected.not_to allow_value(nil).for(:force_daily_publishing) }

  describe 'aggregate_days' do
    subject { aggregate_scheduling.aggregate_days }

    it { is_expected.to be_a(Cuckoo::DaysOfWeek) }

    it 'has at most 7 values' do
      aggregate_scheduling.aggregate_days = '0000000'
      expect(aggregate_scheduling.aggregate_days.days).to eq([])

      aggregate_scheduling.aggregate_days = '1111111'
      expect(aggregate_scheduling.aggregate_days.days).to eq(Cuckoo::DaysOfWeek::SYMBOLIC_DAYS)

      aggregate_scheduling.aggregate_days = '1110100'
      expect(aggregate_scheduling.aggregate_days.days).to eq(%i[monday tuesday wednesday friday])

      aggregate_scheduling.aggregate_days = '1110000'
      expect(aggregate_scheduling.aggregate_days.days).to eq(%i[monday tuesday wednesday])
    end
  end

  describe '#scheduled_job' do
    subject(:scheduled_job) { aggregate_scheduling.scheduled_job }

    it do
      expect(scheduled_job).to have_attributes(
        handler: match(/AggregateScheduling::ScheduledJob/),
        cron: '0 0 * * *'
      )
    end

    it 'does not serialize the whole aggregate scheduing' do
      expect(scheduled_job.handler).not_to include("aggregate_scheduling: !ruby/object:AggregateScheduling\n")
      expect(scheduled_job.payload_object.aggregate_scheduling).to eq(aggregate_scheduling)
    end

    context '#next_schedule' do
      subject { aggregate_scheduling.next_schedule }

      it { is_expected.to be_present }
    end

    context '#reschedule' do
      subject { aggregate_scheduling.reschedule }

      it { expect { subject }.not_to(change { scheduled_job.reload.attributes }) }

      context 'when aggregate job has wrong attributes' do
        before { scheduled_job.update(cron: '1 2 3 4 5') }

        it do
          expect { subject }.to(
            change { scheduled_job.reload.cron }.and(change { scheduled_job.reload.run_at })
          )
        end
      end
    end

    context 'when #aggregate_time changes' do
      subject { aggregate_scheduling.update(aggregate_time: TimeOfDay.new('12', '20')) }

      it do
        expect { subject }.to(
          change { scheduled_job.reload.cron }.to('20 12 * * *').and(change { scheduled_job.reload.run_at })
        )
      end
    end

    context 'when #nightly_aggregate_days changes' do
      subject do
        aggregate_scheduling.update(aggregate_days: Cuckoo::DaysOfWeek.new(monday: true, tuesday: true))
      end

      it { expect { subject }.to change { scheduled_job.reload.cron }.to('0 0 * * 1,2') }
    end

    context 'when aggregate scheduling is destroyed' do
      before { aggregate_scheduling.destroy }

      it { expect { scheduled_job.reload }.to raise_error(ActiveRecord::RecordNotFound) }
    end

    context 'if scheduled job is destroyed' do
      before do
        job = scheduled_job
        aggregate_scheduling.update_column(:scheduled_job_id, nil)
        job.destroy
      end

      context '#next_schedule' do
        subject { aggregate_scheduling.next_schedule }

        it { is_expected.to eq(nil) }
      end

      context '#reschedule' do
        subject { aggregate_scheduling.reschedule }

        it do
          expect { subject }.to change { aggregate_scheduling.scheduled_job }.from(nil).to(
            have_attributes(handler: match(/AggregateScheduling::ScheduledJob/))
          )
        end
      end

      context 'when #aggregate_time changes' do
        subject { aggregate_scheduling.update(aggregate_time: TimeOfDay.new('12', '20')) }

        it do
          expect { subject }.to change { aggregate_scheduling.scheduled_job }.from(nil).to(
            have_attributes(
              handler: match(/AggregateScheduling::ScheduledJob/),
              cron: '20 12 * * *'
            )
          )
        end
      end

      context 'when #aggregate_days changes' do
        subject do
          aggregate_scheduling.update(aggregate_days: Cuckoo::DaysOfWeek.new(monday: true, tuesday: true))
        end

        it do
          expect { subject }.to change { aggregate_scheduling.scheduled_job }.from(nil).to(
            have_attributes(
              handler: match(/AggregateScheduling::ScheduledJob/),
              cron: '0 0 * * 1,2'
            )
          )
        end
      end
    end
  end

  describe AggregateScheduling::ScheduledJob do
    subject(:job) { described_class.new(aggregate_scheduling) }

    let(:context) do
      Chouette.create do
        workgroup do
          referential
        end
      end
    end
    let(:daily_publication) do
      workgroup.publication_setups.create!(
        name: 'Daily',
        force_daily_publishing: true,
        export_options: { 'type' => 'Export::Gtfs' }
      )
    end
    let(:aggregate) do
      workgroup.aggregates.create!(referentials: [context.referential], creator: 'none').tap(&:aggregate!)
    end

    describe '#perform' do
      subject { job.perform }

      it 'calls #aggregate! with the correct arguments' do
        expect(aggregate_scheduling.workgroup).to receive(:aggregate!).with(
          daily_publications: true
        )
        subject
      end

      it 'triggers daily publications' do
        daily_publication
        aggregate

        expect { subject }.to change { daily_publication.publications.count }.by(1)
      end

      context 'when force_daily_publishing is false' do
        let(:force_daily_publishing) { false }

        it 'calls #aggregate! with the correct arguments' do
          expect(aggregate_scheduling.workgroup).to receive(:aggregate!).with(
            daily_publications: false
          )
          subject
        end

        it 'does not trigger daily publications' do
          daily_publication
          aggregate

          expect { subject }.not_to change { daily_publication.publications.count }
        end
      end
    end
  end
end
