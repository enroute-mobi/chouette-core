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

  describe '#worker_died' do
    let(:merge) { Merge.create(workbench: referential.workbench, referentials: [referential, referential]) }

    it 'should set merge status to failed' do
      expect(merge.status).to eq("running")
      merge.worker_died
      expect(merge.status).to eq("failed")
    end
  end

  context '#operation_scheduled?' do
    it 'should look for delayed jobs' do
      merge = Merge.create(workbench: referential.workbench, referentials: [referential, referential])
      other_referential = create(:workbench_referential)
      other_merge = Merge.create(workbench: other_referential.workbench, referentials: [other_referential])

      Delayed::Job.delete_all
      expect(merge.operation_scheduled?).to be_falsy
      other_merge.delay.touch
      expect(merge.operation_scheduled?).to be_falsy
      merge.delay.touch
      expect(merge.operation_scheduled?).to be_truthy
    end
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

  context 'an automatic merge' do
    context "without concurent merge" do
      let(:merge){ Merge.new(workbench: referential.workbench, referentials: [referential, referential], automatic_operation: true) }
      it 'should launch the merge' do
        expect(merge).to receive(:run).and_call_original
        merge.save
        expect(merge).to be_running
      end
    end

    context "with another concurent merge" do
      let(:existing_merge_status){ :running }
      let(:existing_merge){ Merge.create(workbench: referential.workbench, referentials: [referential, referential], status: existing_merge_status) }
      let(:merge){ Merge.new(workbench: referential.workbench, referentials: [referential, referential], automatic_operation: true) }

      it "should be valid" do
        existing_merge
        expect(merge).to be_valid
      end

      it "should be created as pending" do
        existing_merge
        merge.save && merge.run_callbacks(:commit)

        expect(merge).to be_pending
      end

      context "with an already pending merge" do
        let(:pending_merge){ Merge.create(workbench: referential.workbench, referentials: [referential, referential], status: :pending, automatic_operation: true) }

        it 'should not cancel it' do
          existing_merge
          pending_merge
          merge.save && merge.run_callbacks(:commit)
          expect(merge).to be_pending
          expect(pending_merge.reload).to be_pending
        end
      end
    end
  end

  context 'a manual merge' do
    context "without concurent merge" do
      let(:merge){ Merge.new(workbench: referential.workbench, referentials: [referential, referential]) }
      it 'should launch the merge' do
        expect(merge).to receive(:run).and_call_original
        expect(merge).to be_valid
        merge.save
        expect(merge).to be_running
      end
    end

    context "with another concurent merge" do
      let(:existing_merge_status){ :running }
      let(:existing_merge){ Merge.create(workbench: referential.workbench, referentials: [referential, referential], status: existing_merge_status) }
      let(:merge){ Merge.new(workbench: referential.workbench, referentials: [referential, referential]) }

      it "should not be valid" do
        existing_merge
        expect(merge.manual_operation?).to be_truthy
        expect(merge).to_not be_valid
      end
    end
  end

  it "should run next pending merge once it's done" do
    pending_merge = Merge.create(workbench: referential.workbench, referentials: [referential, referential], status: :pending)
    merge = Merge.create(workbench: referential.workbench, referentials: [referential, referential])

    allow_any_instance_of(Merge).to receive(:run) do |m|
      expect(m).to eq pending_merge
    end

    merge.run_pending_operations
  end

  it "should run next pending merge if it fails" do
    pending_merge = Merge.create(workbench: referential.workbench, referentials: [referential, referential], status: :pending)
    merge = Merge.create(workbench: referential.workbench, referentials: [referential, referential])
    expect(merge).to receive(:prepare_new){ raise "oops" }
    allow_any_instance_of(Merge).to receive(:run) do |m|
      expect(m).to eq pending_merge
    end
    begin
      merge.merge!
    rescue
      nil
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

    context 'with previously urgent output', truncation: true do
      let(:merge) { Merge.create(workbench: workbench, referentials: [referential]) }
      let(:output) do
        output = create :workbench_referential, workbench: workbench
        metadata = create(:referential_metadata, lines: [line_referential.lines.first], referential: output)
        workbench.output.update current: output.reload
        metadata.update flagged_urgent_at: 1.hour.ago
        expect(output.reload.contains_urgent_offer?).to be_truthy
        output
      end

      after(:each) do
        Apartment::Tenant.drop(output.slug)
        Apartment::Tenant.drop(referential.slug)
      end

      it "should remove the urgent flag" do
        referential.metadatas.destroy_all
        create(:referential_metadata, lines: [line_referential.lines.last], referential: referential)

        expect(output.contains_urgent_offer?).to be_truthy
        merge.update created_at: Time.now
        merge.prepare_new

        merge.referentials.each do |referential|
          merge.merge_referential_metadata(referential)
        end

        new_referential = workbench.output.new
        expect(new_referential.contains_urgent_offer?).to be_falsy
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
        merge.referentials.each do |referential|
          Merge::Referential::Legacy.new(merge, referential).merge_metadata
        end

        new_referential = workbench.output.new
        expect(new_referential.contains_urgent_offer?).to be_falsy

        workbench.output.update current: new_referential
        expect{ merge.aggregate_if_urgent_offer }.to_not change{ workbench.workgroup.aggregates.count }
      end
    end

    context 'with urgent data' do
      let(:referential){ create :workbench_referential, workbench: workbench }
      let(:referential_urgent){ create :workbench_referential, workbench: workbench }

      before(:each){
        create :referential_metadata, referential: referential
        create :referential_metadata, referential: referential_urgent
        referential_urgent.reload
        referential_urgent.urgent = true
        referential_urgent.save!
      }

      it 'should keep the information' do
        expect(referential_urgent.contains_urgent_offer?).to be_truthy

        merge = Merge.create(workbench: workbench, referentials: [referential, referential_urgent])
        expect{ merge.prepare_new }.to_not raise_error
        merge.referentials.each do |referential|
          Merge::Referential::Legacy.new(merge, referential).merge_metadata
        end

        new_referential = workbench.output.new
        expect(new_referential.contains_urgent_offer?).to be_truthy

        workbench.output.update current: new_referential
        expect{ merge.aggregate_if_urgent_offer }.to change{ workbench.workgroup.aggregates.count }.by 1
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
      expect{ merge }.to change{ ComplianceCheckSet.count }.by 2
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

    it "should reset source refererentials state to active" do
      merge.failed!
      expect(referential.reload.state).to eq :active
    end
  end

  class MergeContext

    attr_accessor :merge_method

    def initialize(attributes = {}, &block)
      attributes.reverse_merge!(merge_method: 'legacy')
      attributes.each { |k,v| send "#{k}=", v }

      @context_block = block
    end

    def create_context
      Chouette.create(&@context_block).tap do |context_block|
        # FIXME
        context_block.referential(:source).tap do |source|
          source.switch do
            source.routes.find(&:update_checksum!)
          end
        end
      end
    end

    def context
      @context ||= create_context
    end

    def create_merge
      attributes = {
        created_at: Time.now,
        workbench: context.workbench,
        referentials: [source],
        new: new,
        merge_method: merge_method.to_s
      }
      Merge.new attributes
    end

    def merge
      @merge ||= create_merge
    end

    def method_missing(name, *arguments)
      if name =~ /^(.*)_(route|journey_pattern)$/
        context.instance name
      else
        super
      end
    end

    def source
      @source ||= context.instance(:source)
    end

    def new
      @new ||= context.instance(:new)
    end

  end

  %i{legacy experimental}.each do |merge_method|
    context "with #{merge_method} method" do

      describe "Route merge" do

        context "when no Route with the same checksum already exists in the merged data set" do

          let(:merge_context) do
            MergeContext.new(merge_method: merge_method) do
              line :line
              referential :source, lines: [:line] do
                time_table :default
                route line: :line do
                  vehicle_journey time_tables: [:default]
                end
              end
            end
          end

          let(:merge) { merge_context.merge }

          it "creates a Route in the merged data set" do
            merge.merge!

            merge.new.switch do
              expect(Chouette::Route.count).to be(1)
            end
          end

        end

        context "when a Route with the same checksum already exists in the merged data set" do

          let(:merge_context) do
            MergeContext.new(merge_method: merge_method) do
              stop_area :first
              stop_area :second
              stop_area :third

              line :line

              referential :source, lines: [:line] do
                time_table :default

                route :source_route, line: :line, with_stops: false do
                  stop_point stop_area: :first
                  stop_point stop_area: :second
                  stop_point stop_area: :third

                  vehicle_journey time_tables: [:default]
                end
              end

              referential :new, lines: [:line], archived_at: Time.now do
                route :existing_route, line: :line, with_stops: false do
                  stop_point stop_area: :first
                  stop_point stop_area: :second
                  stop_point stop_area: :third
                end
              end
            end
          end

          let(:new) { merge_context.new }
          let(:merge) { merge_context.merge }

          let(:existing_route) { merge_context.existing_route }
          let(:source_route) { merge_context.source_route }

          before do
            new.switch do
              existing_route.reload.update_column :checksum, source_route.checksum
            end
          end

          it "doesn't create a new Route" do
            merge.merge!

            merge.new.switch do
              expect(Chouette::Route.find(existing_route.id)).to be_present
              expect(Chouette::Route.count).to be(1)
            end
          end

        end

      end

      describe "JourneyPattern merge" do

        context "when no JourneyPattern with the same checksum already exists in the merged data set" do

          let(:merge_context) do
            MergeContext.new(merge_method: merge_method) do
              line :line
              referential :source, lines: [:line] do
                time_table :default
                route line: :line do
                  vehicle_journey time_tables: [:default]
                end
              end
            end
          end
          let(:merge) { merge_context.merge }

          it "creates a JourneyPattern in the merged data set" do
            merge.merge!

            merge.new.switch do
              expect(Chouette::JourneyPattern.count).to be(1)
            end
          end

        end

        context "when a JourneyPattern with the same checksum already exists in the merged data set" do

          let(:merge_context) do
            MergeContext.new(merge_method: merge_method) do
              stop_area :first
              stop_area :second
              stop_area :third

              line :line

              referential :source, lines: [:line] do
                time_table :default

                route :source_route, line: :line, with_stops: false do
                  stop_point stop_area: :first
                  stop_point stop_area: :second
                  stop_point stop_area: :third

                  journey_pattern :source_journey_pattern do
                    vehicle_journey time_tables: [:default]
                  end
                end
              end

              referential :new, lines: [:line], archived_at: Time.now do
                route :existing_route, line: :line, with_stops: false do
                  stop_point stop_area: :first
                  stop_point stop_area: :second
                  stop_point stop_area: :third

                  journey_pattern :existing_journey_pattern
                end
              end
            end
          end

          let(:source) { merge_context.source }
          let(:new) { merge_context.new }

          let(:merge) { merge_context.merge }

          let(:source_route) { merge_context.source_route }
          let(:existing_route) { merge_context.existing_route }

          let(:source_journey_pattern) { merge_context.source_journey_pattern  }
          let(:existing_journey_pattern) { merge_context.existing_journey_pattern }

          before do
            new.switch do
              existing_route.reload.update_column :checksum, source_route.checksum
              existing_journey_pattern.reload.update_column :checksum, source_journey_pattern.checksum
            end
          end

          it "doesn't create a new JourneyPattern" do
            merge.merge!

            merge.new.switch do
              expect(Chouette::JourneyPattern.find(existing_journey_pattern.id)).to be_present
              expect(Chouette::JourneyPattern.count).to be(1)
            end
          end

        end

        context "when the existing Route hasn't the same position absolute values" do

          let(:merge_context) do
            MergeContext.new(merge_method: merge_method) do
              stop_area :first
              stop_area :second
              stop_area :third

              line :line

              referential :source, lines: [:line] do
                time_table :default

                route :source_route, line: :line, with_stops: false do
                  stop_point stop_area: :first
                  stop_point stop_area: :second
                  stop_point stop_area: :third

                  journey_pattern :merged do
                    vehicle_journey time_tables: [:default]
                  end
                end
              end

              referential :new, lines: [:line], archived_at: Time.now do
                route :existing_route, line: :line, with_stops: false do
                  stop_point stop_area: :first, position: 20
                  stop_point stop_area: :second, position: 30
                  stop_point stop_area: :third, position: 40
                end
              end
            end
          end

          let(:source) { merge_context.source }
          let(:new) { merge_context.new }

          let(:source_route) { merge_context.source_route }
          let(:existing_route) { merge_context.existing_route }

          let(:merge) { merge_context.merge }

          before do
            new.switch do
              existing_route.reload.update_column :checksum, source_route.checksum
            end
          end

          it "create a new JourneyPattern" do
            merge.merge!

            merge.new.switch do
              expect(Chouette::JourneyPattern.count).to be(1)
            end
          end

        end

      end

    end
  end

end
