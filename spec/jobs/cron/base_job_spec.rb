# frozen_string_literal: true

RSpec.describe Cron::BaseJob do
  class self::TestJob < described_class # rubocop:disable Lint/ConstantDefinitionInBlock, Style/ClassAndModuleChildren
    cron '1 2 3 4 *'

    def perform_once
      raise 'Test successfully failed'
    end
  end

  subject(:job_class) { self.class::TestJob }

  describe '#cron_expression' do
    subject { job_class.cron_expression }

    it { is_expected.to eq('1 2 3 4 *') }
  end

  describe '#schedule' do
    subject { job_class.schedule }

    it 'should enqueue job with cron setting' do
      expected_run_at = Time.zone.parse("#{Time.zone.today.year}-04-03T02:01:00")
      expected_run_at = expected_run_at.change(year: Time.zone.today.year + 1) if expected_run_at < DateTime.now
      subject
      expect(Delayed::Job.first).to have_attributes(
        handler: "--- !ruby/object:RSpec::ExampleGroups::CronBaseJob::TestJob {}\n",
        cron: '1 2 3 4 *',
        run_at: expected_run_at
      )
    end

    context 'when already scheduled' do
      before { job_class.schedule }

      it 'should not enqueue twice the same job' do
        expect { subject }.to_not(change { Delayed::Job.count })
      end

      context 'but not with the same cron expression' do
        before { Delayed::Job.first.update(cron: '4 3 2 1 *', run_at: DateTime.now) }

        it 'should not enqueue twice the same job' do
          expect { subject }.to_not(change { Delayed::Job.count })
        end

        it 'should update enqueued job' do
          expected_run_at = Time.zone.parse("#{Time.zone.today.year}-04-03T02:01:00")
          expected_run_at = expected_run_at.change(year: Time.zone.today.year + 1) if expected_run_at < DateTime.now
          subject
          expect(Delayed::Job.first).to have_attributes(
            handler: "--- !ruby/object:RSpec::ExampleGroups::CronBaseJob::TestJob {}\n",
            cron: '1 2 3 4 *',
            run_at: expected_run_at
          )
        end
      end
    end
  end

  describe '#remove' do
    subject { job_class.remove }

    it 'should not crash when job was not already scheduled' do
      expect { subject }.to_not raise_exception
    end

    context 'when already scheduled' do
      before { job_class.schedule }

      it 'should remove enqueued job' do
        expect { subject }.to(change { Delayed::Job.count }.by(-1))
      end
    end
  end

  describe '#schedule_all' do
    subject { described_class.schedule_all } # redefine disable

    it 'should schedule all defined cron jobs' do
      subject
      # rubocop:disable Layout/FirstArrayElementIndentation
      expect(Delayed::Job.where(['handler NOT LIKE ?', '%RSpec::ExampleGroups::%'])).to match_array([
        have_attributes(handler: "--- !ruby/object:Cron::CheckDeadOperationsJob {}\n", cron: '*/5 * * * *'),
        have_attributes(handler: "--- !ruby/object:Cron::CheckNightlyAggregatesJob {}\n", cron: '*/5 * * * *'),
        have_attributes(handler: "--- !ruby/object:Cron::HandleDeadWorkersJob {}\n", cron: '*/5 * * * *'),
        have_attributes(handler: "--- !ruby/object:Cron::PurgeReferentialJob {}\n", cron: '0 3 * * *'),
        have_attributes(handler: "--- !ruby/object:Cron::PurgeWorkgroupsJob {}\n", cron: '0 3 * * *')
      ])
      # rubocop:enable Layout/FirstArrayElementIndentation
    end

    context 'when job is badly scheduled' do
      before do
        Delayed::Job.create!(
          handler: "--- !ruby/object:Cron::PurgeReferentialJob {}\n",
          run_at: DateTime.now,
          cron: '* 3 * * *'
        )
      end

      it 'should reschedule badly scheduled cron jobs' do
        subject
        # rubocop:disable Layout/FirstArrayElementIndentation
        expect(Delayed::Job.where(['handler NOT LIKE ?', '%RSpec::ExampleGroups::%'])).to match_array([
          have_attributes(handler: "--- !ruby/object:Cron::CheckDeadOperationsJob {}\n", cron: '*/5 * * * *'),
          have_attributes(handler: "--- !ruby/object:Cron::CheckNightlyAggregatesJob {}\n", cron: '*/5 * * * *'),
          have_attributes(handler: "--- !ruby/object:Cron::HandleDeadWorkersJob {}\n", cron: '*/5 * * * *'),
          have_attributes(handler: "--- !ruby/object:Cron::PurgeReferentialJob {}\n", cron: '0 3 * * *'),
          have_attributes(handler: "--- !ruby/object:Cron::PurgeWorkgroupsJob {}\n", cron: '0 3 * * *')
        ])
        # rubocop:enable Layout/FirstArrayElementIndentation
      end
    end

    context 'when disabling some jobs' do
      before { allow(Cron::CheckNightlyAggregatesJob).to receive(:enabled).and_return(false) }

      it 'should not schedule disabled cron jobs' do
        subject
        # rubocop:disable Layout/FirstArrayElementIndentation
        expect(Delayed::Job.where(['handler NOT LIKE ?', '%RSpec::ExampleGroups::%'])).to match_array([
          have_attributes(handler: "--- !ruby/object:Cron::CheckDeadOperationsJob {}\n", cron: '*/5 * * * *'),
          have_attributes(handler: "--- !ruby/object:Cron::HandleDeadWorkersJob {}\n", cron: '*/5 * * * *'),
          have_attributes(handler: "--- !ruby/object:Cron::PurgeReferentialJob {}\n", cron: '0 3 * * *'),
          have_attributes(handler: "--- !ruby/object:Cron::PurgeWorkgroupsJob {}\n", cron: '0 3 * * *')
        ])
        # rubocop:enable Layout/FirstArrayElementIndentation
      end

      context 'when jobs are enqueued' do
        before do
          Delayed::Job.create!(
            handler: "--- !ruby/object:Cron::CheckNightlyAggregatesJob {}\n",
            run_at: DateTime.now,
            cron: '*/5 * * * *'
          )
        end

        it 'should unschedule disabled cron jobs' do
          subject
          # rubocop:disable Layout/FirstArrayElementIndentation
          expect(Delayed::Job.where(['handler NOT LIKE ?', '%RSpec::ExampleGroups::%'])).to match_array([
            have_attributes(handler: "--- !ruby/object:Cron::CheckDeadOperationsJob {}\n", cron: '*/5 * * * *'),
            have_attributes(handler: "--- !ruby/object:Cron::HandleDeadWorkersJob {}\n", cron: '*/5 * * * *'),
            have_attributes(handler: "--- !ruby/object:Cron::PurgeReferentialJob {}\n", cron: '0 3 * * *'),
            have_attributes(handler: "--- !ruby/object:Cron::PurgeWorkgroupsJob {}\n", cron: '0 3 * * *')
          ])
          # rubocop:enable Layout/FirstArrayElementIndentation
        end
      end
    end
  end

  describe '#scheduled?' do
    subject { job_class.scheduled? }

    it { is_expected.to eq(false) }

    context 'when scheduled' do
      before { job_class.schedule }

      it { is_expected.to eq(true) }

      context 'but not with the same cron expression' do
        before { Delayed::Job.first.update(cron: '4 3 2 1 *') }

        it { is_expected.to eq(false) }
      end
    end
  end

  describe '#delayed_job' do
    subject { job_class.delayed_job }

    it { is_expected.to be_nil }

    context 'when scheduled' do
      let(:enqueued_job) { job_class.schedule }

      before do
        Delayed::Job.create!(handler: "--- !ruby/object:Cron::BaseJob {}\n", run_at: DateTime.now, cron: '1 * * * *')
        enqueued_job
        Delayed::Job.create!(handler: "--- !ruby/object:Cron::BaseJob {}\n", run_at: DateTime.now, cron: '1 * * * *')
      end

      it { is_expected.to eq(enqueued_job) }
    end
  end

  describe '#cron_name' do
    subject { job_class.cron_name }

    it { is_expected.to eq('Test') }
  end

  describe '#perform' do
    subject { job_class.new.perform }

    it 'should catch raised error' do
      expect(Chouette::Safe).to receive(:capture) do |message, error|
        expect(message).to eq('Test Cron Job failed')
        expect(error).to be_a(RuntimeError)
      end
      expect { subject }.to_not raise_exception
    end
  end
end
