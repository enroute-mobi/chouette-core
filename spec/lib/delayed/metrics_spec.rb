# frozen_string_literal: true

RSpec.describe Delayed::Metrics do
  describe '.measure' do
    context 'when cooldown? is true' do
      before { allow(Delayed::Metrics).to receive(:cooldown?).and_return(true) }

      it {
        expect(Delayed::Metrics::Measure).to_not receive(:new)
        Delayed::Metrics.measure
      }

      context 'ignore_cooldown option is true' do
        it {
          expect(Delayed::Metrics::Measure).to receive(:new).and_return(Delayed::Metrics::Measure.new)
          Delayed::Metrics.measure ignore_cooldown: true
        }
      end
    end

    context 'when cooldown? is false' do
      before { allow(Delayed::Metrics).to receive(:cooldown?).and_return(false) }

      it {
        expect(Delayed::Metrics::Measure).to receive(:new).and_return(Delayed::Metrics::Measure.new)
        Delayed::Metrics.measure
      }
    end
  end

  describe Delayed::Metrics::Publisher::Prometheus do
    subject(:publisher) { described_class.new }

    let(:registry) { Prometheus::Client::Registry.new }
    before { allow(publisher).to receive(:registry).and_return(registry) }

    describe '#publish' do
      subject { publisher.publish(metrics) }

      context 'when no jobs.pending_count is present' do
        let(:metrics) { [double(name: 'dummy')] }

        it { expect { subject }.to_not change { registry.exist?(:jobs_pending) }.from(false) }
      end

      context 'when a Metric jobs.pending_count has the value 42' do
        let(:metrics) { [double(name: 'jobs.pending_count', value: 42)] }

        it { expect { subject }.to change { registry.exist?(:jobs_pending) }.to(true) }

        describe 'the published gauge' do
          subject(:gauge) { registry.get(:jobs_pending) }

          before { publisher.publish(metrics) }

          it { is_expected.to have_attributes(get: 42.0) }
        end
      end
    end
  end
end
