RSpec.describe Control::ServiceCountTrend do

  describe Control::ServiceCountTrend::Run do

    let(:control_list_run) do
      Control::List::Run.create referential: referential, workbench: workbench
    end

    let(:control_run) do
      control_run= Control::ServiceCountTrend::Run.create(
        control_list_run: control_list_run,
        criticity: "warning",
        weeks_before: 2,
        weeks_after: 2,
        maximum_difference: 20,
        position: 0
      )
    end

    let(:journey_pattern1) { create :journey_pattern }
    let(:journey_pattern2) { create :journey_pattern }

    let(:line_referential) { create :line_referential }
    let(:workbench) { create :workbench, line_referential: line_referential }
    let!(:line) { create :line, line_referential: line_referential }
    let(:route1) { journey_pattern1.route }
    let(:route2) { journey_pattern2.route }

    let(:referential)  { create :workbench_referential, workbench: workbench }
  
    before do
      referential.switch
      journey_pattern1.route.update line: line
      journey_pattern2.route.update line: line

      Stat::JourneyPatternCoursesByDate.create([
        {
          date: "2022-09-13".to_date,
          count: 1,
          journey_pattern: journey_pattern1,
          route: route1,
          line: line
        },
        {
          date: "2022-09-20".to_date,
          count: 1,
          journey_pattern: journey_pattern1,
          route: route1,
          line: line
        },
        {
          date: "2022-09-27".to_date,
          count: 1,
          journey_pattern: journey_pattern1,
          route: route1,
          line: line
        },
        {
          date: "2022-10-04".to_date,
          count: 1,
          journey_pattern: journey_pattern1,
          route: route1,
          line: line
        },
        {
          date: "2022-10-11".to_date,
          count: 1,
          journey_pattern: journey_pattern1,
          route: route1,
          line: line
        },

        {
          date: "2022-09-13".to_date,
          count: 1,
          journey_pattern: journey_pattern2,
          route: route2,
          line: line
        },
        {
          date: "2022-09-20".to_date,
          count: 0,
          journey_pattern: journey_pattern2,
          route: route2,
          line: line
        },
        {
          date: "2022-09-27".to_date,
          count: 1,
          journey_pattern: journey_pattern2,
          route: route2,
          line: line
        },
        {
          date: "2022-10-04".to_date,
          count: 1,
          journey_pattern: journey_pattern2,
          route: route2,
          line: line
        },
        {
          date: "2022-10-11".to_date,
          count: 1,
          journey_pattern: journey_pattern2,
          route: route2,
          line: line
        }
      ])

    end

    let(:expected_message) do
      an_object_having_attributes({
        source: line,
        criticity: 'warning',
        message_attributes: {
          'date' => '2022-09-20',
          'line' => line.id
        }
      })
    end

    it 'should detect anomaly at "2022-09-20"' do
      control_run.run

      expect(control_run.control_messages).to include(expected_message)
    end

    describe "#context" do

      let(:control_run) do
        Control::ServiceCountTrend::Run.create(
          control_list_run: control_list_run,
          criticity: "warning",
          weeks_before: 2,
          weeks_after: 2,
          maximum_difference: 20,
          position: 0,
          control_context_run: control_context_run
        )
      end

      let(:control_context_run) do
        Control::Context::TransportMode::Run.create name: "Control Context Run 1", control_list_run: control_list_run, options: {transport_mode: "bus"}
      end

      context 'when transport_mode is bus' do
        before do
          line.update transport_mode: 'bus'
        end

        it 'should detect anomaly at "2022-09-20"' do
          control_run.run

          expect(control_run.control_messages).to include(expected_message)
        end
      end

      context 'when transport_mode is tram' do
        before do
          line.update transport_mode: 'tram'
        end

        it 'should be empty' do
          control_run.run

          expect(control_run.control_messages).to be_empty
        end
      end
    end
  end
end