# frozen_string_literal: true

RSpec.describe Delayed::AutoKillPlugin do
  describe Delayed::AutoKillPlugin::Status do
    subject(:status) { described_class.new }

    describe 'must_stop?' do
      subject { status.must_stop? }

      context 'when worker_idle?' do
        before { allow(status).to receive(:worker_idle?).and_return(true) }

        it { is_expected.to be_truthy }
      end
    end

    describe '#memory_limit' do
      subject { status.memory_limit }

      it { is_expected.to eq(1024) }
    end

    describe '#memory_maps_limit' do
      subject { status.memory_maps_limit }

      it { is_expected.to eq(1024) }
    end

    describe '#memory_used' do
      subject { status.memory_used }

      context 'when Chouette::Benchmark.current_usage is 42.0' do
        before { allow(Chouette::Benchmark).to receive(:current_usage).and_return(42.0) }

        it { is_expected.to eq(42) }
      end
    end

    describe '#memory_maps_used' do
      subject { status.memory_maps_used }

      context 'when Chouette::Benchmark.current_map_usage is 42.0' do
        before { allow(Chouette::Benchmark).to receive(:current_map_usage).and_return(42.0) }

        it { is_expected.to eq(42) }
      end
    end

    describe '#worker_count' do
      subject { status.worker_count }

      context 'when Delayed::Heartbeat::Worker.count is 42' do
        before { allow(Delayed::Heartbeat::Worker).to receive(:count).and_return(42) }

        it { is_expected.to eq(42) }
      end
    end

    describe '#pending_jobs', skip: 'Mock method fails ?!' do
      subject { status.pending_jobs }

      context 'when Delayed::Job.pending_count is 42' do
        before { allow(Delayed::Job).to receive(:pending_count).and_return(42) }

        it { is_expected.to eq(42) }
      end
    end

    describe '#maximum_idle_workers' do
      subject { status.maximum_idle_workers }

      context 'when Delayed::AutoKillPlugin.maximum_idle_workers is nil' do
        before { allow(Delayed::AutoKillPlugin).to receive(:maximum_idle_workers).and_return(nil) }

        it { is_expected.to eq(Float::INFINITY) }
      end

      context 'when Delayed::AutoKillPlugin.maximum_idle_workers is 0' do
        before { allow(Delayed::AutoKillPlugin).to receive(:maximum_idle_workers).and_return(0) }

        it { is_expected.to eq(Float::INFINITY) }
      end

      context 'when Delayed::AutoKillPlugin.maximum_idle_workers is 42' do
        before { allow(Delayed::AutoKillPlugin).to receive(:maximum_idle_workers).and_return(42) }

        it { is_expected.to eq(42) }
      end
    end

    describe '#worker_count_expected' do
      subject { status.worker_count_expected }

      context 'when #pending_jobs is 42 and #maximum_idle_workers is 1' do
        before do
          allow(status).to receive(:pending_jobs).and_return(42)
          allow(status).to receive(:maximum_idle_workers).and_return(1)
        end

        it { is_expected.to eq(42) }
      end

      context 'when #pending_jobas is 0 and #maximum_idle_workers is 1' do
        before do
          allow(status).to receive(:pending_jobs).and_return(42)
          allow(status).to receive(:maximum_idle_workers).and_return(1)
        end

        it { is_expected.to eq(42) }
      end

      context 'when #pending_jobas is 0 and #maximum_idle_workers is infinite' do
        before do
          allow(status).to receive(:pending_jobs).and_return(42)
          allow(status).to receive(:maximum_idle_workers).and_return(Float::INFINITY)
        end

        it { is_expected.to eq(Float::INFINITY) }
      end
    end

    describe '#worker_idle?' do
      subject { status.worker_idle? }

      context 'when #worker_count is 1 and #worker_count_expected is 0' do
        before do
          allow(status).to receive(:worker_count).and_return(1)
          allow(status).to receive(:worker_count_expected).and_return(0)
        end

        it { is_expected.to be_truthy }
      end

      context 'when #worker_count is 1 and #worker_count_expected is 1' do
        before do
          allow(status).to receive(:worker_count).and_return(1)
          allow(status).to receive(:worker_count_expected).and_return(1)
        end

        it { is_expected.to be_falsy }
      end

      context 'when #worker_count is 0 and #worker_count_expected is 1' do
        before do
          allow(status).to receive(:worker_count).and_return(0)
          allow(status).to receive(:worker_count_expected).and_return(1)
        end

        it { is_expected.to be_falsy }
      end
    end
  end
end
