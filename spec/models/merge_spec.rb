require "rails_helper"

RSpec.describe Merge do
  let(:stop_area_referential){ create :stop_area_referential }
  let(:line_referential){ create :line_referential }
  let(:company){ create :company, line_referential: line_referential }
  let(:workbench){ create :workbench, line_referential: line_referential, stop_area_referential: stop_area_referential }
  let(:referential){
    ref = create :referential, workbench: workbench, organisation: workbench.organisation
    create(:referential_metadata, lines: line_referential.lines.limit(3), referential: ref)
    ref.reload
  }
  let(:referential_metadata){ referential.metadatas.last }

  before(:each) do
    4.times { create :line, line_referential: line_referential, company: company, network: nil }
    10.times { create :stop_area, stop_area_referential: stop_area_referential }
  end

  it "should be valid" do
    merge = Merge.new(workbench: referential.workbench, referentials: [referential, referential])
    expect(merge).to be_valid
  end

  context "#current?" do
    let(:merge){ build_stubbed :merge }
    context "when the current output is mine" do
      before(:each) do
        merge.new = merge.workbench.output.current
      end

      it "should be true" do
        expect(merge.current?).to be_truthy
      end
    end

    context "when the current output is not mine" do
      before(:each) do
        merge.new = build_stubbed(:referential)
      end

      it "should be false" do
        expect(merge.current?).to be_falsy
      end
    end
  end

  context "with another concurent merge" do
    before do
       Merge.create(workbench: referential.workbench, referentials: [referential, referential])
    end

    it "should not be valid" do
      merge = Merge.new(workbench: referential.workbench, referentials: [referential, referential])
      expect(merge).to_not be_valid
    end
  end

  it "should clean previous merges" do
    3.times do
      other_workbench = create(:workbench)
      other_referential = create(:referential, workbench: other_workbench, organisation: other_workbench.organisation)
      m = Merge.create!(workbench: other_workbench, referentials: [other_referential])
      m.update status: :successful
      m = Merge.create!(workbench: referential.workbench, referentials: [referential, referential])
      m.update status: :successful
      m = Merge.create!(workbench: referential.workbench, referentials: [referential, referential])
      m.update status: :failed
    end
    expect(Merge.count).to eq 9
    Merge.keep_operations = 2
    Merge.last.clean_previous_operations
    expect(Merge.count).to eq 8
  end

  it "should not remove referentials locked for aggregation" do
    workbench = referential.workbench
    locked_merge = Merge.create!(workbench: workbench, referentials: [referential, referential])
    locked_merge.update status: :successful
    locked = create(:referential, referential_suite: workbench.output)
    locked_merge.update new: locked
    workbench.update locked_referential_to_aggregate: locked
    m = nil
    3.times do
      m = Merge.create!(workbench: workbench, referentials: [referential, referential])
      m.update status: :successful
    end
    expect(Merge.count).to eq 4
    Merge.keep_operations = 2
    Merge.last.clean_previous_operations
    expect(Merge.count).to eq 3
    expect { locked_merge.reload }.to_not raise_error
    expect { locked.reload }.to_not raise_error
    expect { m.reload }.to_not raise_error
  end

  it "should not remove referentials used in previous aggregations" do
    workbench = referential.workbench
    aggregate = Aggregate.create(workgroup: workbench.workgroup, referentials: [referential, referential])
    other_referential = create(:referential, workbench: referential.workbench, organisation: referential.organisation)
    should_disappear = Merge.create!(workbench: workbench, referentials: [referential], new: other_referential)
    should_disappear.update status: :successful
    m = Merge.create!(workbench: workbench, referentials: [referential], new: other_referential)
    m.update status: :successful
    3.times do
      m = Merge.create!(workbench: workbench, referentials: [referential, referential], new: referential)
      m.update status: :successful
    end
    Merge.keep_operations = 1
    expect(Merge.count).to eq 5
    expect { Merge.last.clean_previous_operations }.to change { Merge.count }.by -1
    expect(Merge.where(id: should_disappear.id).count).to be_zero
  end

  context "#prepare_new" do
    context "when some lines are no longer available", truncation: true do
      let(:merge){Merge.create(workbench: workbench, referentials: [referential, referential]) }

      before do
        ref = create(:workbench_referential, workbench: workbench)
        create(:referential_metadata, lines: [line_referential.lines.first], referential: ref)
        create(:referential_metadata, lines: [line_referential.lines.last], referential: ref)
        workbench.output.update current: ref.reload

        allow(workbench).to receive(:lines){ Chouette::Line.where(id: line_referential.lines.last.id) }
      end

      after(:each) do
        Apartment::Tenant.drop(workbench.output.current.slug)
        Apartment::Tenant.drop(referential.slug)
      end

      it "should work" do
        expect{ merge.prepare_new }.to_not raise_error
      end

      context "when no lines are available anymore" do
        before do
          allow(workbench).to receive(:lines){ Chouette::Line.none }
        end

        it "should work" do
          expect{ merge.prepare_new }.to_not raise_error
        end
      end
    end

    context "with no current output" do
      let(:merge){Merge.create(workbench: workbench, referentials: [referential, referential]) }

      before(:each) do
        workbench.output.update current_id: Referential.last.id + 1
        expect(workbench.output.current).to be_nil
      end

      it "should not allow the creation of a referential from scratch if the workbench has previous merges" do
        m = Merge.create(workbench: workbench, referentials: [referential, referential])
        m.update status: :successful
        expect{ merge.prepare_new }.to raise_error RuntimeError
      end

      it "should allow the creation of a referential from scratch if the workbench has no previous merges" do
        m = Merge.create(workbench: workbench, referentials: [referential, referential])
        m.update status: :failed
        expect{ merge.prepare_new }.to_not raise_error
      end

      it "should create a referential with ready: false" do
        merge.update created_at: Time.now
        merge.prepare_new
        expect(workbench.output.new.ready).to be false
      end
    end
  end

  context "with before_merge compliance_control_sets" do
    let(:merge) { Merge.create(workbench: workbench, referentials: [referential, referential]) }
    before do
      @control_set = create :compliance_control_set, organisation: workbench.organisation
      workbench.update owner_compliance_control_set_ids: {before_merge: @control_set.id}
    end

    it "should run checks" do
      expect{merge.merge}.to change{ComplianceCheckSet.count}.by 2
    end

    context "when the control_set has been destroyed" do
      before do
        @control_set.destroy
      end
      it "should not fail" do
        expect{merge.merge}.to change{ComplianceCheckSet.count}.by 0
      end
    end

    context "when the control_set fails" do
      it "should reset referential state to active" do
        merge.merge
        check_set = ComplianceCheckSet.last
        ComplianceCheckSet.where.not(id: check_set.id).update_all notified_parent_at: Time.now
        expect(check_set.referential).to eq referential
        merge.compliance_check_sets.update_all status: :successful
        check_set.update status: :failed
        check_set.do_notify_parent
        expect(referential.reload.state).to eq :active
      end
    end
  end

  it "should set source refererentials state to pending" do
    merge = Merge.create!(workbench: referential.workbench, referentials: [referential, referential])
    merge.merge
    expect(referential.reload.state).to eq :pending
  end

  context "when it fails" do
    let(:merge) { Merge.create!(workbench: referential.workbench, referentials: [referential, referential]) }
    before(:each){
      allow(merge).to receive(:prepare_new).and_raise
    }

    it "should reset source refererentials state to active" do
      merge.merge
      begin
        merge.merge!
      rescue
      end
      expect(referential.reload.state).to eq :active
    end
  end
end
