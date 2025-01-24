# frozen_string_literal: true

RSpec.describe Delayed::ReadyToRunWithoutLockedAt do
  describe '.reserve' do
    subject { Delayed::Job.reserve(worker) }

    around do |example|
      Timecop.freeze do
        example.run
      end
    end

    let(:worker_name) { 'Test-1' }
    let(:worker) { double(name: worker_name) }

    let(:delayed_job_run_at) { 1.day.ago }
    let(:delayed_job_locked_at) { nil }
    let(:delayed_job_locked_by) { nil }
    let(:delayed_job_failed_at) { nil }

    let(:job_attributes) do
      {
        handler: double(perform: true),
        run_at: delayed_job_run_at,
        locked_at: delayed_job_locked_at,
        locked_by: delayed_job_locked_by,
        failed_at: delayed_job_failed_at
      }
    end
    let!(:job) { Delayed::Job.create!(job_attributes) }

    context 'when run_at is in the past' do
      it { is_expected.to eq(job) }

      context 'with failed_at' do
        let(:delayed_job_failed_at) { Time.zone.now }

        it { is_expected.to be_nil }
      end

      context 'when job is locked' do
        let(:delayed_job_locked_by) { 'Test-2' }

        context 'since a few seconds' do
          let(:delayed_job_locked_at) { 1.second.ago }

          it { is_expected.to be_nil }
        end

        context 'since exactly max_run_time seconds' do
          let(:delayed_job_locked_at) { Delayed::Worker.max_run_time.ago }

          it { is_expected.to be_nil }
        end

        context 'since more than exactly max_run_time seconds' do
          let(:delayed_job_locked_at) { (Delayed::Worker.max_run_time + 1).ago }

          it { is_expected.to be_nil }
        end
      end
    end

    context 'when run_at is now' do
      let(:delayed_job_run_at) { Time.zone.now }

      it { is_expected.to eq(job) }
    end

    context 'when run_at is in the future' do
      let(:delayed_job_run_at) { 1.day.from_now }

      it { is_expected.to be_nil }

      context 'when locked_by is the very same worker' do
        let(:delayed_job_locked_by) { worker_name }

        it { is_expected.to eq(job) }

        context 'with failed_at' do
          let(:delayed_job_failed_at) { Time.zone.now }

          it { is_expected.to be_nil }
        end
      end
    end
  end
end
