# frozen_string_literal: true

RSpec.describe Workgroup, type: :model do

  let(:context) { Chouette.create { workgroup } }
  let(:workgroup) { context.workgroup }

  context "associations" do
    it{ should have_many(:workbenches) }

    it { is_expected.to belong_to(:owner).required }
    it { is_expected.to belong_to(:stop_area_referential).required }
    it { is_expected.to belong_to(:line_referential).required }

    it{ should validate_uniqueness_of(:name) }
    it{ should validate_uniqueness_of(:stop_area_referential_id) }
    it{ should validate_uniqueness_of(:line_referential_id) }
    it{ should validate_uniqueness_of(:shape_referential_id) }

    it 'is valid with both associations' do
      expect(workgroup).to be_valid
    end
  end

  describe "#organisations" do
    let(:context) do
      Chouette.create do
        workgroup do
          workbench :first
          workbench :second
        end
      end
    end

    let(:workbench1) { context.workbench(:first) }
    let(:workbench2) { context.workbench(:second) }

    subject { workgroup.organisations }

    it "includes organisations of all workbenches in the workgroup" do
      is_expected.to match_array([workbench1.organisation, workbench2.organisation])
    end
  end

  describe 'aggregate_urgent_data!' do
    subject { workgroup.aggregate_urgent_data! }

    let(:aggregated_at) { nil }

    before do
      Timecop.freeze
      workgroup.update_column(:aggregated_at, aggregated_at) if aggregated_at
    end

    after do
      Timecop.return
    end

    context 'when workgroup has never been aggregated' do
      context 'without referential' do
        it 'does not aggregate' do
          expect { subject }.not_to(change { workgroup.aggregates.count })
        end
      end

      context 'with referentials' do
        let(:context) do
          Chouette.create do
            workgroup do
              workbench(:locked_referential_to_aggregate_workbench) do
                referential
                referential(:locked_referential_to_aggregate_referential)
              end
              workbench(:current_workbench) do
                referential
                referential(:current_referential)
              end
              workbench do
                referential(:non_current_referential)
              end
            end
          end
        end

        before do
          context.workbench(:locked_referential_to_aggregate_workbench).update(
            locked_referential_to_aggregate: context.referential(:locked_referential_to_aggregate_referential)
          )
          context.workbench(:current_workbench).create_output!(current: context.referential(:current_referential))
        end

        it 'aggregates all current referentials' do
          expect { subject }.to change { workgroup.aggregates.count }.by(1).and change { Delayed::Job.count }.by(1)
          expect(workgroup.aggregates.last).to have_attributes(
            referentials: match_array(
              %i[
                locked_referential_to_aggregate_referential
                current_referential
              ].map { |i| context.referential(i) }
            ),
            creator: 'webservice',
            notification_target: 'none'
          )
        end
      end
    end

    context 'when workgroup has already been aggregated' do
      let(:aggregated_at) { 10.minutes.ago }

      context 'when 1 referential is created after last aggregate' do
        let(:context) do
          Chouette.create do
            workgroup do
              workbench(:flag_as_urgent_workbench) do
                referential(flagged_urgent_at: 5.minutes.ago, with_metadatas: true)
                referential(:flag_as_urgent_referential, flagged_urgent_at: 5.minutes.ago, with_metadatas: true)
              end
              workbench(:other_workbench) do
                referential(:other_referential)
              end
            end
          end
        end

        before do
          %w[flag_as_urgent other].each do |i|
            context.workbench(:"#{i}_workbench").create_output!(current: context.referential(:"#{i}_referential"))
          end
        end

        it 'aggregates all current referentials' do
          expect { subject }.to change { workgroup.aggregates.count }.by(1).and change { Delayed::Job.count }.by(1)
          expect(workgroup.aggregates.last).to have_attributes(
            referentials: match_array(
              %i[
                flag_as_urgent_referential
                other_referential
              ].map { |i| context.referential(i) }
            ),
            creator: 'webservice',
            notification_target: 'none'
          )
        end
      end

      context 'when workbench is flagged as urgent before last aggregate' do
        let(:context) do
          Chouette.create do
            workgroup do
              workbench do
                referential(flagged_urgent_at: 15.minutes.ago, with_metadatas: true)
              end
            end
          end
        end

        before { context.workbench.create_output!(current: context.referential) }

        it 'does not aggregate any referential' do
          expect { subject }.not_to(change { workgroup.aggregates.count })
        end
      end

      context 'when workbench is not flagged as urgent' do
        let(:context) do
          Chouette.create do
            workgroup do
              workbench do
                referential
              end
            end
          end
        end

        before { context.workbench.create_output!(current: context.referential) }

        it 'does not aggregate any referential' do
          expect { subject }.not_to(change { workgroup.aggregates.count })
        end
      end
    end
  end

  describe 'aggregate!' do
    let(:aggregate_options) { {} }
    subject { workgroup.aggregate!(**aggregate_options) }

    let(:aggregated_at) { nil }
    let(:daily_publication) do
      workgroup.publication_setups.create!(
        name: 'Daily',
        force_daily_publishing: true,
        export_options: { 'type' => 'Export::Gtfs' }
      )
    end
    let(:other_publication) do
      workgroup.publication_setups.create!(name: 'Other', export_options: { 'type' => 'Export::Gtfs' })
    end
    let(:some_referential) { context.referential(:some_referential) }
    let(:aggregate) do
      workgroup.aggregates.create!(referentials: [some_referential], creator: 'none').tap(&:aggregate!)
    end

    before do
      Timecop.freeze
      workgroup.update_column(:aggregated_at, aggregated_at) if aggregated_at
    end
    after { Timecop.return }

    context 'when workgroup has never been aggregated' do
      context 'without referential' do
        let(:context) do
          Chouette.create do
            workgroup do
              referential(:some_referential)
            end
          end
        end

        it 'does not aggregate' do
          expect { subject }.not_to(change { workgroup.aggregates.count })
        end

        context 'with publications' do
          before do
            daily_publication
            other_publication
            aggregate
          end

          it 'does not publish last successful aggregate' do
            expect { subject }.not_to(change { Publication.count })
          end

          context 'with daily_publications option' do
            let(:aggregate_options) { { daily_publications: true } }

            it 'publishes last successful aggregate' do
              expect { subject }.to(
                change { daily_publication.publications.count }.and(not_change { other_publication.publications.count })
              )
            end

            context 'when no aggregate is successful' do
              let(:aggregate) do
                workgroup.aggregates.create!(referentials: [some_referential], creator: 'none').tap do |aggregate|
                  aggregate.update_column(:status, :failed)
                end
              end

              it 'does not publish aggregate' do
                expect { subject }.not_to(change { Publication.count })
              end
            end
          end
        end
      end

      context 'with referentials' do
        let(:context) do
          Chouette.create do
            workgroup do
              workbench(:locked_referential_to_aggregate_workbench) do
                referential(:some_referential)
                referential(:locked_referential_to_aggregate_referential)
              end
              workbench(:current_workbench) do
                referential
                referential(:current_referential)
              end
              workbench do
                referential(:non_current_referential)
              end
            end
          end
        end

        before do
          context.workbench(:locked_referential_to_aggregate_workbench).update(
            locked_referential_to_aggregate: context.referential(:locked_referential_to_aggregate_referential)
          )
          context.workbench(:current_workbench).create_output!(current: context.referential(:current_referential))
        end

        it 'aggregates all current referentials' do
          expect { subject }.to change { workgroup.aggregates.count }.by(1).and change { Delayed::Job.count }.by(1)
          expect(workgroup.aggregates.last).to have_attributes(
            referentials: match_array(
              %i[
                locked_referential_to_aggregate_referential
                current_referential
              ].map { |i| context.referential(i) }
            ),
            creator: 'creator'
          )
        end

        context 'with aggregate_attributes option' do
          let(:aggregate_options) { { aggregate_attributes: { creator: 'CRON', notification_target: 'user' } } }

          it 'creates aggregate with specified aggregate attributes' do
            subject
            expect(workgroup.aggregates.last).to have_attributes(
              creator: 'CRON',
              notification_target: 'user'
            )
          end
        end
      end
    end

    context 'when workgroup has already been aggregated' do
      let(:aggregated_at) { 10.minutes.ago }

      context 'when 1 referential is created after last aggregate' do
        let(:context) do
          Chouette.create do
            workgroup do
              workbench(:created_after_workbench) do
                referential(:some_referential)
                referential(:created_after_referential)
              end
              workbench(:other_workbench) do
                referential(:other_referential)
              end
            end
          end
        end

        before do
          %w[created_after other].each do |i|
            context.workbench(:"#{i}_workbench").create_output!(current: context.referential(:"#{i}_referential"))
          end
        end

        it 'aggregates all current referentials' do
          expect { subject }.to change { workgroup.aggregates.count }.by(1).and change { Delayed::Job.count }.by(1)
          expect(workgroup.aggregates.last).to have_attributes(
            referentials: match_array(
              %i[
                created_after_referential
                other_referential
              ].map { |i| context.referential(i) }
            )
          )
        end
      end

      context 'when 1 referential is created before last aggregate' do
        let(:aggregated_at) { 10.minutes.from_now }

        let(:context) do
          Chouette.create do
            workgroup do
              workbench do
                referential(:some_referential)
              end
            end
          end
        end

        before { context.workbench.create_output!(current: context.referential(:some_referential)) }

        it 'does not aggregate any referential' do
          expect { subject }.not_to(change { workgroup.aggregates.count })
        end

        context 'with publications' do
          let(:aggregate_options) { { daily_publications: true } }

          before do
            daily_publication
            aggregate
          end

          it 'publishes last aggregate' do
            expect { subject }.to(change { Publication.count })
          end
        end
      end
    end
  end

  describe "#nightly_aggregate_days" do
    it 'should be a instance of Cuckoo::Timetable::DaysOfWeek' do
      expect(
        workgroup.nightly_aggregate_days.is_a?(Cuckoo::Timetable::DaysOfWeek)
      ).to be_truthy
    end

    it 'should have at most 7 values' do
      workgroup.nightly_aggregate_days = '0000000'
      expect(workgroup.nightly_aggregate_days.days).to eq([])

      workgroup.nightly_aggregate_days = '1111111'
      expect(workgroup.nightly_aggregate_days.days).to eq(Cuckoo::Timetable::DaysOfWeek::SYMBOLIC_DAYS)

      workgroup.nightly_aggregate_days = '1110100'
      expect(workgroup.nightly_aggregate_days.days).to eq(%i[monday tuesday wednesday friday])

      workgroup.nightly_aggregate_days = '1110000'
      expect(workgroup.nightly_aggregate_days.days).to eq(%i[monday tuesday wednesday])
    end
  end

  describe '#scheduled_aggregate_job' do
    context 'when aggregate job is not scheduled' do
      context 'when #nightly_aggregate_enabled becomes true' do
        subject(:enable_nightly_aggregate) { workgroup.update(nightly_aggregate_enabled: true) }

        it do
          expect { subject }.to change { workgroup.scheduled_aggregate_job }.from(nil).to(
            have_attributes(
              handler: match(/Workgroup::ScheduledAggregateJob/),
              cron: '0 0 * * *'
            )
          )
        end

        it 'does not serialize the whole workgroup' do
          subject
          expect(workgroup.scheduled_aggregate_job.handler).not_to include("workgroup: !ruby/object:Workgroup\n")
          expect(workgroup.scheduled_aggregate_job.payload_object.workgroup).to eq(workgroup)
        end

        context '#next_aggregate_schedule' do
          subject { workgroup.next_aggregate_schedule }

          before { enable_nightly_aggregate }

          it { is_expected.to be_present }
        end

        context '#reschedule_aggregate' do
          subject { workgroup.reschedule_aggregate }

          before { enable_nightly_aggregate }

          it { expect { subject }.not_to(change { workgroup.scheduled_aggregate_job.reload.attributes }) }

          context 'when aggregate job has wrong attributes' do
            before { workgroup.scheduled_aggregate_job.update(cron: '1 2 3 4 5') }

            it do
              expect { subject }.to(
                change { workgroup.scheduled_aggregate_job.reload.cron }.and(
                  change { workgroup.scheduled_aggregate_job.reload.run_at }
                )
              )
            end
          end
        end

        context 'when #nightly_aggregate_enabled becomes false' do
          subject { workgroup.update(nightly_aggregate_enabled: false) }

          before { enable_nightly_aggregate }

          it { expect { subject }.to change { workgroup.reload.scheduled_aggregate_job }.from(be_present).to(nil) }
        end

        context 'when #nightly_aggregate_time changes' do
          subject { workgroup.update(nightly_aggregate_time: TimeOfDay.new('12', '20')) }

          before { enable_nightly_aggregate }

          it do
            expect { subject }.to(
              change { workgroup.scheduled_aggregate_job.reload.cron }.to('20 12 * * *').and(
                change { workgroup.scheduled_aggregate_job.reload.run_at }
              )
            )
          end
        end

        context 'when #nightly_aggregate_days changes' do
          subject do
            workgroup.update(nightly_aggregate_days: Cuckoo::Timetable::DaysOfWeek.new(monday: true, tuesday: true))
          end

          before { enable_nightly_aggregate }

          it do
            expect { subject }.to change { workgroup.scheduled_aggregate_job.reload.cron }.to('0 0 * * 1,2')
          end

          context 'becomes empty' do
            subject { workgroup.update(nightly_aggregate_days: Cuckoo::Timetable::DaysOfWeek.none) }

            it { expect { subject }.to change { workgroup.reload.scheduled_aggregate_job }.from(be_present).to(nil) }
          end
        end

        context 'when workgroup is destroyed' do
          subject { workgroup.destroy }

          before { enable_nightly_aggregate }

          it do
            job = workgroup.scheduled_aggregate_job
            subject
            expect { job.reload }.to raise_error(ActiveRecord::RecordNotFound)
          end
        end

        context 'if scheduled job is destroyed' do
          before do
            enable_nightly_aggregate
            job = workgroup.scheduled_aggregate_job
            workgroup.update_column(:scheduled_aggregate_job_id, nil)
            job.destroy
          end

          context '#next_aggregate_schedule' do
            subject { workgroup.next_aggregate_schedule }

            it { is_expected.to eq(nil) }
          end

          context '#reschedule_aggregate' do
            subject { workgroup.reschedule_aggregate }

            it do
              expect { subject }.to change { workgroup.scheduled_aggregate_job }.from(nil).to(
                have_attributes(handler: match(/Workgroup::ScheduledAggregateJob/))
              )
            end
          end

          context 'when #nightly_aggregate_time changes' do
            subject { workgroup.update(nightly_aggregate_time: TimeOfDay.new('12', '20')) }

            it do
              expect { subject }.to change { workgroup.scheduled_aggregate_job }.from(nil).to(
                have_attributes(
                  handler: match(/Workgroup::ScheduledAggregateJob/),
                  cron: '20 12 * * *'
                )
              )
            end
          end

          context 'when #nightly_aggregate_days changes' do
            subject do
              workgroup.update(nightly_aggregate_days: Cuckoo::Timetable::DaysOfWeek.new(monday: true, tuesday: true))
            end

            it do
              expect { subject }.to change { workgroup.scheduled_aggregate_job }.from(nil).to(
                have_attributes(
                  handler: match(/Workgroup::ScheduledAggregateJob/),
                  cron: '0 0 * * 1,2'
                )
              )
            end

            context 'becomes empty' do
              subject { workgroup.update(nightly_aggregate_days: Cuckoo::Timetable::DaysOfWeek.none) }

              it { expect { subject }.not_to change { workgroup.scheduled_aggregate_job }.from(nil) }
            end
          end
        end
      end

      context '#reschedule_aggregate' do
        subject { workgroup.reschedule_aggregate }

        it { expect { subject }.not_to change { workgroup.scheduled_aggregate_job }.from(nil) }
      end

      context 'when #nightly_aggregate_time changes' do
        subject { workgroup.update(nightly_aggregate_time: TimeOfDay.new('12', '20')) }

        it { expect { subject }.not_to change { workgroup.scheduled_aggregate_job }.from(nil) }
      end

      context 'when #nightly_aggregate_days changes' do
        subject do
          workgroup.update(nightly_aggregate_days: Cuckoo::Timetable::DaysOfWeek.new(monday: true, tuesday: true))
        end

        it { expect { subject }.not_to change { workgroup.scheduled_aggregate_job }.from(nil) }
      end
    end

    context 'when aggregate job is scheduled' do
      before do
        workgroup.update(
          scheduled_aggregate_job: Delayed::Job.enqueue(
            Workgroup::ScheduledAggregateJob.new(workgroup),
            cron: '1 2 3 4 5'
          )
        )
      end

      context '#next_aggregate_schedule' do
        subject { workgroup.next_aggregate_schedule }

        it { is_expected.to eq(nil) }
      end

      context '#reschedule_aggregate' do
        subject { workgroup.reschedule_aggregate }

        it { expect { subject }.to change { workgroup.reload.scheduled_aggregate_job }.from(be_present).to(nil) }
      end

      context 'when #nightly_aggregate_time changes' do
        subject { workgroup.update(nightly_aggregate_time: TimeOfDay.new('12', '20')) }

        it { expect { subject }.to change { workgroup.reload.scheduled_aggregate_job }.from(be_present).to(nil) }
      end

      context 'when #nightly_aggregate_days changes' do
        subject do
          workgroup.update(nightly_aggregate_days: Cuckoo::Timetable::DaysOfWeek.new(monday: true, tuesday: true))
        end

        it { expect { subject }.to change { workgroup.reload.scheduled_aggregate_job }.from(be_present).to(nil) }
      end
    end
  end

  describe Workgroup::ScheduledAggregateJob do
    subject(:job) { Workgroup::ScheduledAggregateJob.new(workgroup) }

    describe '#perform' do
      subject { job.perform }

      before do
        workgroup.update(nightly_aggregate_notification_target: 'user')
        expect(workgroup).to receive(:aggregate_schedule_enabled?).and_return(aggregate_schedule_enabled)
      end

      context 'when aggregate_schedule_enabled? is true' do
        let(:aggregate_schedule_enabled) { true }

        it 'calls #aggregate! with the correct arguments' do
          expect(workgroup).to receive(:aggregate!).with(
            creator: 'CRON',
            aggregate_attributes: { notification_target: 'user' },
            daily_publications: true,
            log: true
          )
          subject
        end
      end

      context 'when aggregate_schedule_enabled? is false' do
        let(:aggregate_schedule_enabled) { false }

        it 'does not call aggregate!' do
          expect(workgroup).not_to receive(:aggregate!)
          subject
        end
      end
    end
  end

  describe "when a workgroup is purged" do
    let!(:workgroup) { create(:workgroup, deleted_at: Time.now) }
    let!(:workbench) { create(:workbench, workgroup: workgroup) }
    let!(:new_referential) { create(:referential, organisation: workbench.organisation, workbench: workbench) }
    let!(:field){ create(:custom_field, workgroup: workgroup) }
    let!(:publication_api) { create(:publication_api, workgroup: workgroup) }
    let!(:publication_setup) { create(:publication_setup, workgroup: workgroup)}

    let!(:line) { create(:line, line_referential: referential.line_referential) }
    let!(:route) { create(:route, line: line)}
    let!(:journey_pattern) { create(:journey_pattern, route: route) }

    it "should cascade destroy every related object" do
      Workgroup.purge_all

      # The schema that contains our deleted referential data should be destroyed (route, jp, timetables, etc)
      expect(ActiveRecord::Base.connection.schema_names).not_to include(new_referential.slug)

      expect(Chouette::Line.where(id: line.id).exists?).to be_truthy

      [
        workgroup,
        workbench,
        new_referential,
        field,
        new_referential,
        publication_api,
        publication_setup
      ].each do |record|
        expect { record.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe '#route_planner' do
    subject { workgroup.route_planner }

    it { is_expected.to be_a(RoutePlanner::Config) }
    it { is_expected.to an_object_responding_to(:batch) }

    context "when owner has the feature 'route_planner'" do
      before do
        workgroup.owner.tap { |o| o.features << 'route_planner' }.save
      end

      it do
        resolver_classes = a_collection_containing_exactly(RoutePlanner::Resolver::TomTom,
                                                           RoutePlanner::Resolver::Cache)
        is_expected.to have_attributes(resolver_classes: resolver_classes)
      end
    end

    context "when owner hasn't the feature 'route_planner'" do
      it { is_expected.to have_attributes(resolver_classes: an_object_satisfying('an empty collection', &:empty?)) }
    end
  end

  describe '#reverse_geocode' do
    subject { workgroup.reverse_geocode }

    it { is_expected.to be_a(ReverseGeocode::Config) }
    it { is_expected.to an_object_responding_to(:batch) }

    context "when owner has the feature 'reverse_geocode'" do
      before do
        workgroup.owner.tap { |o| o.features << 'reverse_geocode' }.save
      end

      it do
        resolver_classes = a_collection_containing_exactly(ReverseGeocode::Resolver::TomTom,
                                                           ReverseGeocode::Resolver::Cache)
        is_expected.to have_attributes(resolver_classes: resolver_classes)
      end
    end

    context "when owner hasn't the feature 'reverse_geocode'" do
      it { is_expected.to have_attributes(resolver_classes: an_object_satisfying('an empty collection', &:empty?)) }
    end
  end
end
