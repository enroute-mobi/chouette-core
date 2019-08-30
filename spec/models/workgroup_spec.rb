require 'rails_helper'

RSpec.describe Workgroup, type: :model do
  context "associations" do
    let( :workgroup ){ build_stubbed :workgroup, line_referential_id: 53, stop_area_referential_id: 42 }

    it{ should have_many(:workbenches) }
    it{ should validate_presence_of(:owner) }
    it{ should validate_uniqueness_of(:name) }
    it{ should validate_uniqueness_of(:stop_area_referential_id) }
    it{ should validate_uniqueness_of(:line_referential_id) }

    it 'is not valid without a stop_area_referential' do
      workgroup.stop_area_referential_id = nil
      expect( workgroup ).not_to be_valid
    end
    it 'is not valid without a line_referential' do
      workgroup.line_referential_id = nil
      expect( workgroup ).not_to be_valid
    end
    it 'is valid with both assoications' do
      expect( workgroup ).to be_valid
    end
  end

  context "find organisations" do
    let( :workgroup ){ create :workgroup }
    let!( :workbench1 ){ create :workbench, workgroup: workgroup }
    let!( :workbench2 ){ create :workbench, workgroup: workgroup }

    it{ expect( Set.new(workgroup.organisations) ).to eq(Set.new([ workbench1.organisation, workbench2.organisation ])) }
  end

  describe "#nightly_aggregate_timeframe?" do
    let(:workgroup) { create(:workgroup, nightly_aggregate_time: aggregation_time, nightly_aggregate_enabled: nightly_aggregate_enabled) }
    let(:aggregation_time) { "15:15:00" }
    let(:nightly_aggregate_enabled){ false }
    context "when nightly_aggregate_enabled is true" do
      let(:nightly_aggregate_enabled){ true }

      it "returns true when inside timeframe" do
        Timecop.freeze(Time.now.beginning_of_day + 6.months + 15.hours + 15.minutes) do
          expect(workgroup.reload.nightly_aggregate_timeframe?).to be_truthy
        end
      end

      it "returns false when outside timeframe" do
        Timecop.freeze(Time.now.beginning_of_day + 2.hours) do
          expect(workgroup.nightly_aggregate_timeframe?).to be_falsy
        end
      end

      it "returns false when inside timeframe but already done" do
        workgroup.nightly_aggregated_at = Time.now.beginning_of_day + 6.months + 15.hours + 15.minutes
        Timecop.freeze(Time.now.beginning_of_day + 6.months + 15.hours + 15.minutes) do
          expect(workgroup.nightly_aggregate_timeframe?).to be_falsy
        end
      end
    end

    context "when nightly_aggregate_enabled is false" do
      it "is false even within timeframe" do
        Timecop.freeze(Time.now.beginning_of_day + 6.months + 15.hours + 15.minutes) do
          expect(workgroup.nightly_aggregate_timeframe?).to be_falsy
        end
      end
    end
  end

  describe "#nightly_aggregate!" do
    let(:workgroup) { create(:workgroup, nightly_aggregate_enabled: true, nightly_aggregate_time: '15:15:00') }

    context "when no aggregatable referential is found" do
      it "returns with a log message" do
        Timecop.freeze(Time.now.beginning_of_day + 15.hours + 15.minutes) do
          # expect(Rails.logger).to receive(:info).with(/\ANo aggregatable referential found/)

          expect { workgroup.nightly_aggregate! }.not_to change {
            workgroup.aggregates.count
          }
        end
      end
    end

    context "when we have rollbacked to a previous aggregate" do
      let(:workbench) { create(:workbench, workgroup: workgroup) }
      let(:referential) { create(:referential, organisation: workbench.organisation) }
      let(:aggregatable) { create(:workbench_referential, workbench: workbench) }
      let(:referential_2) { create(:referential, organisation: workbench.organisation) }
      let(:aggregate) { create(:aggregate, workgroup: workgroup)}
      let(:aggregate_2) { create(:aggregate, workgroup: workgroup)}
      let(:referential_suite) { create(:referential_suite, current: aggregatable) }
      let(:workgroup_referential_suite) { create(:referential_suite, current: referential_2, referentials: [referential, referential_2]) }

      before do
        aggregate.update new: referential, status: :successful
        aggregatable
        aggregate_2.update new: referential_2

        workbench.update(output: referential_suite)
        workgroup.update(output: workgroup_referential_suite)
        aggregate.rollback!
        expect(workgroup.output.current).to eq referential
      end

      it "returns with a log message" do
        Timecop.freeze(Time.now.beginning_of_day + 6.months + 15.hours + 15.minutes) do
          # expect(Rails.logger).to receive(:info).with(/\ANo aggregatable referential found/)

          expect { workgroup.nightly_aggregate! }.not_to change {
            workgroup.aggregates.count
          }
        end
      end
    end

    context "when aggregatable referentials are found" do
      let(:workbench) { create(:workbench, workgroup: workgroup) }
      let(:referential) { create(:referential, organisation: workbench.organisation, workbench: workbench) }
      let(:referential_suite) { create(:referential_suite, current: referential) }

      before do
        workbench.update(output: referential_suite)
      end

      it "creates a new aggregate" do
        Timecop.freeze(Time.now.beginning_of_day + 6.months + 15.hours + 15.minutes) do
          expect { referential.workgroup.nightly_aggregate! }.to change {
            referential.workgroup.aggregates.count
          }.by(1)
          expect(referential.workgroup.aggregates.where(creator: 'CRON')).to exist
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
    let!(:calendar) { create(:calendar, workgroup: workgroup)}


    let!(:line) { create(:line, line_referential: referential.line_referential) }
    let!(:route) { create(:route, line: line)}
    let!(:journey_pattern) { create(:journey_pattern, route: route) }


    it "should cascade destroy every related object" do
      Workgroup.purge_all

      # The schema that contains our deleted referential data should be destroyed (route, jp, timetables, etc)
      expect(ActiveRecord::Base.connection.schema_names).not_to include(new_referential.slug)

      expect(Chouette::Line.where(id: line.id).exists?).to be_truthy

      [workgroup, workbench, new_referential, field, calendar, new_referential, publication_api, publication_setup].each do |record|
        expect{record.reload}.to raise_error ActiveRecord::RecordNotFound
      end
    end

  end
end
