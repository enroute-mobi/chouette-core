# frozen_string_literal: true

RSpec.describe Cron::StartBlockedPendingMergesJob do
  it { is_expected.to be_a_kind_of(Cron::MinutesJob) }

  describe '#perform' do
    subject { described_class.new.perform }

    let(:context) do
      Chouette.create do
        workbench do
          referential
        end
      end
    end
    let(:before_merges) { nil }
    let(:pending_merge) do
      context.workbench.merges.create!(referentials: [context.referential], creator: 'P').tap(&:pending!)
    end
    let(:after_merges) { nil }

    before do
      before_merges
      pending_merge
      after_merges
      Delayed::Job.delete_all
    end

    context 'with 1 successful merge and 1 pending merge' do
      let(:before_merges) do
        context.workbench.merges.create!(
          referentials: [context.referential],
          creator: 'S0'
        ).tap do |m|
          m.update(status: 'successful')
        end
      end

      it 'restarts pending merge' do
        subject
        expect(pending_merge.reload).to have_attributes(status: 'running')
        expect(Delayed::Job.last).to be_present
      end

      it 'logs which merge is started' do
        expect(Rails.logger).to(
          receive(:warn).with("Force Merge start for Merge##{pending_merge.id} in Workbench##{context.workbench.id}")
        )
        subject
      end
    end

    context 'with 3 successful merges and 1 pending merge' do
      let(:before_merges) do
        3.times.map do |i|
          context.workbench.merges.create!(
            referentials: [context.referential],
            creator: "S#{i}"
          ).tap do |m|
            m.update(status: 'successful')
          end
        end
      end

      it 'restarts pending merge' do
        subject
        expect(pending_merge.reload).to have_attributes(status: 'running')
        expect(Delayed::Job.last).to be_present
      end
    end

    context 'with 1 successful merge and 3 pending merges' do
      let(:before_merges) do
        context.workbench.merges.create!(
          referentials: [context.referential],
          creator: 'S0'
        ).tap do |m|
          m.update(status: 'successful')
        end
      end
      let(:after_merges) do
        2.times do |i|
          context.workbench.merges.create!(
            referentials: [context.referential],
            creator: "S#{i}",
            automatic_operation: true
          )
        end
      end

      it 'restarts first pending merge' do
        subject
        expect(pending_merge.reload).to have_attributes(status: 'running')
        expect(Delayed::Job.last).to be_present
      end
    end

    context 'with 1 pending merge' do
      it 'does nothing' do
        subject
        expect(pending_merge.reload).to have_attributes(status: 'pending')
        expect(Delayed::Job.last).not_to be_present
      end
    end

    context 'with 1 successful merge, 1 pending merge and 1 successful merge' do
      let(:before_merges) do
        context.workbench.merges.create!(
          referentials: [context.referential],
          creator: 'S0'
        ).tap do |m|
          m.update(status: 'successful')
        end
      end
      let(:after_merges) do
        context.workbench.merges.create!(
          referentials: [context.referential],
          creator: 'S1',
          automatic_operation: true
        ).tap do |m|
          m.update(status: 'successful')
        end
      end

      it 'does nothing' do
        subject
        expect(pending_merge.reload).to have_attributes(status: 'pending')
        expect(Delayed::Job.last).not_to be_present
      end
    end

    context 'with 1 failed merge and 1 pending merge' do
      let(:before_merges) do
        context.workbench.merges.create!(
          referentials: [context.referential],
          creator: 'S0'
        ).tap(&:failed!)
      end

      it 'does nothing' do
        subject
        expect(pending_merge.reload).to have_attributes(status: 'pending')
        expect(Delayed::Job.last).not_to be_present
      end
    end
  end
end
