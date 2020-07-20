RSpec.describe Aggregate, type: :model do
  context 'an automatic aggregate' do
    context "without concurent aggregate" do
      let(:aggregate){ Aggregate.new(workgroup: referential.workgroup, referentials: [referential, referential], automatic_operation: true) }
      it 'should launch the aggregate' do
        expect(aggregate).to receive(:run).and_call_original
        aggregate.save
        expect(aggregate).to be_running
      end
    end

    context "with another concurent aggregate" do
      let(:existing_aggregate_status){ :running }
      let(:existing_aggregate){ Aggregate.create(workgroup: referential.workgroup, referentials: [referential, referential], status: existing_aggregate_status) }
      let(:aggregate){ Aggregate.new(workgroup: referential.workgroup, referentials: [referential, referential], automatic_operation: true) }

      it "should be valid" do
        existing_aggregate
        expect(aggregate).to be_valid
      end

      it "should be created as pending" do
        existing_aggregate
        aggregate.save && aggregate.run_callbacks(:commit)

        expect(aggregate).to be_pending
      end

      context "with an already pending aggregate" do
        let(:pending_aggregate){ Aggregate.create(workgroup: referential.workgroup, referentials: [referential, referential], status: :pending, automatic_operation: true) }

        it 'should cancel it' do
          existing_aggregate
          pending_aggregate
          aggregate.save && aggregate.run_callbacks(:commit)
          expect(aggregate).to be_pending
          expect(pending_aggregate.reload).to be_canceled
        end
      end
    end

    it "should run next pending aggregate once it's done" do
      pending_aggregate = Aggregate.create(workgroup: referential.workgroup, referentials: [referential, referential], status: :pending)
      aggregate = Aggregate.create(workgroup: referential.workgroup, referentials: [referential, referential], automatic_operation: true)

      allow_any_instance_of(Aggregate).to receive(:run) do |m|
        expect(m).to eq pending_aggregate
      end

      aggregate.run_pending_operations
    end

    it "should run next pending aggregate if it fails" do
      pending_aggregate = Aggregate.create(workgroup: referential.workgroup, referentials: [referential, referential], status: :pending)
      aggregate = Aggregate.create(workgroup: referential.workgroup, referentials: [referential, referential], automatic_operation: true)
      expect(aggregate).to receive(:prepare_new){ raise "oops" }
      allow_any_instance_of(Aggregate).to receive(:run) do |m|
        expect(m).to eq pending_aggregate
      end
      begin
        aggregate.aggregate!
      rescue
        nil
      end
    end

    it "should clean previous aggregates" do
      referential.workgroup.update(owner: referential.organisation)
      15.times do
        a = Aggregate.create!(workgroup: referential.workgroup, referentials: [referential, referential], automatic_operation: true)
        a.update status: :successful
      end
      Aggregate.last.aggregate!
      expect(Aggregate.count).to eq 10
    end
  end

  context 'a manual aggregate' do
    context "without concurent aggregate" do
      let(:aggregate){ Aggregate.new(workgroup: referential.workgroup, referentials: [referential, referential]) }
      it 'should launch the aggregate' do
        expect(aggregate).to receive(:run).and_call_original
        aggregate.save
        expect(aggregate).to be_running
      end
    end

    context "with another concurent aggregate" do
      let(:existing_aggregate_status){ :running }
      let(:existing_aggregate){ Aggregate.create(workgroup: referential.workgroup, referentials: [referential, referential], status: existing_aggregate_status) }
      let(:aggregate){ Aggregate.new(workgroup: referential.workgroup, referentials: [referential, referential]) }

      it "should not be valid" do
        existing_aggregate
        expect(aggregate).to_not be_valid
      end
    end
  end

  context 'with publications' do
    let(:aggregate) { create :aggregate }
    let!(:enabled_publication_setup) { create :publication_setup, workgroup: aggregate.workgroup, enabled: true }
    let!(:disabled_publication_setup) { create :publication_setup, workgroup: aggregate.workgroup, enabled: false }

    it 'should be published' do
      ids = []
      allow_any_instance_of(PublicationSetup).to receive(:publish) do |obj|
        ids << obj.id
      end

      aggregate.publish
      expect(ids).to eq [enabled_publication_setup.id]
    end
  end

  describe '#worker_died' do
    let(:aggregate) { Aggregate.create!(workgroup: referential.workgroup, referentials: [referential, referential]) }

    it 'should set aggregate status to failed' do
      expect(aggregate.status).to eq("running")
      aggregate.worker_died
      expect(aggregate.status).to eq("failed")
    end
  end

  context "#rollback?" do
    let(:workbench){ create :workbench }
    let(:output) do
      out = workbench.workgroup.output
      3.times do
        out.referentials << create(:workbench_referential, workbench: workbench, organisation: workbench.organisation)
      end
      out.current = out.referentials.last
      out.save!
      out
    end

    def create_referential
      create(:workbench_referential, organisation: workbench.organisation, workbench: workbench, metadatas: [create(:referential_metadata)])
    end

    def create_aggregate(attributes = {})
      attributes = {
        workgroup: workbench.workgroup,
        status: :successful,
        referentials: 2.times.map { create_referential.tap(&:merged!) }
      }.merge(attributes)
      status = attributes.delete(:status)
      aggregate = create :aggregate, attributes
      aggregate.update status: status
      aggregate
    end

    let(:previous_aggregate){ create_aggregate }
    let(:previous_failed_aggregate){ create_aggregate status: :failed }
    let(:aggregate){ create_aggregate }
    let(:final_aggregate){ create_aggregate }

    before(:each) do
      previous_aggregate.update new: output.referentials.sort_by(&:created_at)[0]
      aggregate.update new: output.referentials.sort_by(&:created_at)[1]
      final_aggregate.update new: output.referentials.sort_by(&:created_at)[2]
    end

    context "when the current output is mine" do
      before(:each) do
        aggregate.new = output.current
      end

      it "should raise an error" do
        expect { aggregate.rollback! }.to raise_error RuntimeError
      end
    end

    context "when the current output is not mine" do
      it "should set the output current referential" do
        aggregate.rollback!
        expect(output.reload.current).to eq aggregate.new
      end

      it "should change the other aggregates status" do
        expect(aggregate).to receive(:publish)
        aggregate.rollback!
        expect(previous_aggregate.reload.status).to eq "successful"
        expect(previous_failed_aggregate.reload.status).to eq "failed"
        expect(final_aggregate.reload.status).to eq "canceled"
      end
    end

    context 'when another concurent referential has been created meanwhile' do
      before(:each) do
        concurent = create_referential.tap(&:active!)
        metadata = final_aggregate.referentials.last.metadatas.last
        concurent.update metadatas: [create(:referential_metadata, line_ids: metadata.line_ids, periodes: metadata.periodes)]
      end

      it 'should leave the referential archived' do
        aggregate.rollback!
        r = final_aggregate.referentials.last
        expect(r.archived_at).to_not be_nil
      end
    end
  end
end
