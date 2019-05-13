require 'rails_helper'

RSpec.describe Aggregate, type: :model do
  context "with another concurent aggregate" do
    before do
       Aggregate.create(workgroup: referential.workbench.workgroup, referentials: [referential, referential])
    end

    it "should not be valid" do
      aggregate = Aggregate.new(workgroup: referential.workbench.workgroup, referentials: [referential, referential])
      expect(aggregate).to_not be_valid
    end
  end

  it "should clean previous aggregates" do
    referential.workbench.workgroup.update(owner: referential.organisation)
    15.times do
      a = Aggregate.create!(workgroup: referential.workbench.workgroup, referentials: [referential, referential])
      a.update status: :successful
    end
    Aggregate.last.aggregate!
    expect(Aggregate.count).to eq 10
  end

  it "should clean all non successful aggregates created before first successful" do
    referential.workbench.workgroup.update(owner: referential.organisation)
    5.times { Aggregate.create!(workgroup: referential.workbench.workgroup, referentials: [referential, referential], status: 'failed', created_at: DateTime.now) }

    5.times { Aggregate.create!(workgroup: referential.workbench.workgroup, referentials: [referential, referential], status: 'successful', created_at: DateTime.now + 1.day) }

    Aggregate.create!(workgroup: referential.workbench.workgroup, referentials: [referential, referential], status: 'failed', created_at: DateTime.now + 2.days)

    5.times { Aggregate.create!(workgroup: referential.workbench.workgroup, referentials: [referential, referential], status: 'successful', created_at: DateTime.now + 3.days) }

    binding.pry
    Aggregate.last.aggregate!
    binding.pry
    expect(Aggregate.count).to eq 11
    expect(Aggregate.except_successful.count).to eq 1
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
      create :aggregate, attributes
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
