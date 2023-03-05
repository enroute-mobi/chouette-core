RSpec.describe Aggregate, type: :model do

  describe "aggregate!" do

    context "when two Workbenches provides data for the same Line on the same Period" do
      let(:context) do
        Chouette.create do
          line :line
          workbench :workbench do
            referential lines: [ :line ], periods: [ Date.parse("2030-06-01")..Date.parse("2030-06-30") ] do
              time_table :time_table_1, periods: [ Date.parse("2030-06-01")..Date.parse("2030-06-30") ]
              vehicle_journey time_tables: [:time_table_1]
            end
          end
          workbench :other_workbench do
            referential lines: [ :line ], periods: [ Date.parse("2030-06-01")..Date.parse("2030-06-30") ] do
              time_table :time_table_2, periods: [ Date.parse("2030-06-01")..Date.parse("2030-06-30") ]
              vehicle_journey time_tables: [:time_table_2]
            end
          end
        end
      end

      let(:workbench) { context.workbench(:workbench) }
      let(:other_workbench) { context.workbench(:other_workbench) }

      let(:aggregate) { Aggregate.create! workgroup: context.workgroup, referentials: context.referentials }

      let(:workbench_priority) { 1 }
      before { workbench.update priority: workbench_priority }

      context "after aggregate" do

        before { aggregate.aggregate! }

        describe "#aggregate_resources" do
          let(:aggregate_resources) { aggregate.reload.resources }
          let(:workbench_names) { aggregate_resources.map(&:workbench_name) }
          let(:first_vehicle_journey_count) { context.referentials.first.switch { |ref| ref.vehicle_journeys.count } }
          let(:last_vehicle_journey_count) { context.referentials.last.switch { |ref| ref.vehicle_journeys.count } }

          it "aggregate resources contain workbench names" do
            expect(workbench_names).to match_array([ workbench.name, other_workbench.name ])
          end

          it "calculate metrics for the first referential" do
            expect(aggregate_resources).to include(
              an_object_having_attributes(
                metrics: {
                  'vehicle_journey_count' => first_vehicle_journey_count,
                  'overlapping_period_count' => 0
                }
              )
            )
          end

          it "calculate metrics for the last referential" do
            expect(aggregate_resources).to include(
              an_object_having_attributes(
                metrics: {
                  'vehicle_journey_count' => last_vehicle_journey_count,
                  'overlapping_period_count' => 0
                }
              )
            )
          end
        end

        context "the aggregated dataset" do
          subject(:aggregated_dataset) { aggregate.new }
          before { aggregated_dataset.switch }

          context "when the two Workbenches have the same priority" do
            it "contains two Vehicle Journeys" do
              expect(aggregated_dataset.vehicle_journeys.count).to eq(2)
            end

            it "contains two TimeTables" do
              expect(aggregated_dataset.time_tables.count).to eq(2)
            end
          end

          context "when a Workbench has a lower priority (2 instead of 1)" do
            let(:workbench_priority) { 2 }

            it "contains a single Vehicle Journey" do
              expect(aggregated_dataset.vehicle_journeys.count).to eq(1)
            end

            it "contains a single TimeTable" do
              expect(aggregated_dataset.vehicle_journeys.count).to eq(1)
            end
          end
        end

      end

    end

    context "when two Workbenches provides data for the same Line on the same Period with a shared timetable" do
      let(:context) do
        Chouette.create do
          line :line
          line :other_line
          workbench :workbench do
            referential lines: [ :line, :other_line ], periods: [ Date.parse("2030-06-01")..Date.parse("2030-06-30") ] do
              # This Timetable is used by two Vehicle Journeys associated with different Lines
              time_table :shared_time_table, periods: [ Date.parse("2030-06-01")..Date.parse("2030-06-30") ]

              route line: :line do
                vehicle_journey time_tables: [:shared_time_table]
              end

              route line: :other_line do
                vehicle_journey time_tables: [:shared_time_table]
              end
            end
          end
          workbench do
            # This Referential provides a Vehicle Journey on a single Line
            referential lines: [ :line ], periods: [ Date.parse("2030-06-01")..Date.parse("2030-06-30") ] do
              time_table :time_table, periods: [ Date.parse("2030-06-01")..Date.parse("2030-06-30") ]

              route line: :line do
                vehicle_journey time_tables: [:time_table]
              end
            end
          end
        end
      end

      let(:workbench) { context.workbench(:workbench) }
      let(:aggregate) { Aggregate.create! workgroup: context.workgroup, referentials: context.referentials }

      let(:line) { context.line(:line) }

      let(:workbench_priority) { 1 }
      before { workbench.update priority: workbench_priority }

      context "after aggregate" do
        before { aggregate.aggregate! }

        context "the aggregated dataset" do
          subject(:aggregated_dataset) { aggregate.new }
          before { aggregated_dataset.switch }

          context "when the two Workbenches have the same priority" do

            it "contains three Vehicle Journeys" do
              expect(aggregated_dataset.vehicle_journeys.count).to eq(3)
            end

            it "contains two TimeTables" do
              expect(aggregated_dataset.time_tables.count).to eq(2)
            end
          end

          # TODO Support shared timetables
          #
          # context "when a Workbench has a lower priority (2 instead of 1)" do
          #   let(:workbench_priority) { 2 }
          #
          #   it "contains a single Vehicle Journey on the Line" do
          #     expect(aggregated_dataset.vehicle_journeys.with_lines(line).count).to eq(1)
          #   end
          #
          #   it "contains two TimeTables", pending: "Shared timetable not supported" do
          #     expect(aggregated_dataset.time_tables.count).to eq(2)
          #   end
          # end
        end
      end

      context "when a Workbench has a lower priority (2 instead of 1)" do
        let(:workbench_priority) { 2 }

        it "raises an error because of shared timetables" do
          expect { aggregate.aggregate! }.to raise_error(RuntimeError)
        end
      end
    end

  end

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

  describe '#notification_recipients' do
    let(:context) do
      Chouette.create do
        organisation :owner do
          user :user1, email: 'user1@chouette.test'
          user :user2, email: 'user2@chouette.test'
        end
        workgroup owner: :owner do
          workbench organisation: :owner do
            referential
          end
        end
      end
    end

    let(:user) { context.user(:user1) }
    let(:aggregate) { Aggregate.create! workgroup: context.workgroup, referentials: context.referentials, user: user }

    subject { aggregate.notification_recipients }

    context 'when notification_target is "workbench"' do
      before { aggregate.notification_target = 'workbench' }

      it { is_expected.to contain_exactly('user1@chouette.test', 'user2@chouette.test') }
    end

    context 'when notification_target is "user"' do
      before { aggregate.notification_target = 'user' }

      it { is_expected.to contain_exactly('user1@chouette.test') }
    end
  end
end
