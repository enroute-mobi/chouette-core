# frozen_string_literal: true

RSpec.describe Delayed::Heartbeat do
  describe '.delete_timed_out_workers' do
    let(:timed_out_worker) do
      Delayed::Heartbeat::Worker.create! name: 'test', last_heartbeat_at: 1.hour.ago
    end
    let!(:job) do
      Delayed::Job.create! handler: double(perform: true), locked_by: timed_out_worker.name
    end

    it 'invokes the hook :dead_worker for all associated jobs' do
      expect_any_instance_of(Delayed::Job).to receive(:hook).with(:dead_worker)
      Delayed::Heartbeat.delete_timed_out_workers
    end
  end
end
