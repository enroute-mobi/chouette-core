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

    it 'does not serialize the whole aggregate scheduing' do
      expect(scheduled_job.handler).not_to include("aggregate_scheduling: !ruby/object:AggregateScheduling\n")
      expect(scheduled_job.payload_object.aggregate_scheduling).to eq(aggregate_scheduling)
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
      workgroup.publication_setups.create(
        name: 'Daily',
        force_daily_publishing: true,
        export_setup: {
          type: 'Export::Setup::Gtfs',
          scope_setup: {
            type: 'Export::Setup::Scope::PublishedReferential'
          }
        }
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

          expect { subject }.not_to(change { daily_publication.publications.count })
        end
      end
    end
  end
end
