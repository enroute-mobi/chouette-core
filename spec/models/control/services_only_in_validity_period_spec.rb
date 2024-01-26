RSpec.describe Control::ServicesOnlyInValidityPeriod do

  describe Control::ServicesOnlyInValidityPeriod::Run do

    let(:control_list_run) do
      Control::List::Run.create referential: referential, workbench: workbench
    end

    let(:control_run) do
      control_run= Control::ServicesOnlyInValidityPeriod::Run.create(
        control_list_run: control_list_run,
        criticity: "warning",
        position: 0
      )
    end

    let(:journey_pattern1) { create :journey_pattern }
    let(:journey_pattern2) { create :journey_pattern }

    let(:line_referential) { create :line_referential }
    let(:workbench) { create :workbench, line_referential: line_referential }
    let!(:line) { create :line, line_referential: line_referential }
    let!(:faulty_line) do 
      create :line, name: 'Faulty Line' , line_referential: line_referential, active_from: '2030-01-01'.to_date
    end

    let(:route1) { journey_pattern1.route }
    let(:route2) { journey_pattern2.route }

    let(:referential)  { create :workbench_referential, workbench: workbench }
  
    before do
      referential.switch
      journey_pattern1.route.update line: faulty_line
      journey_pattern2.route.update line: line

      referential.service_counts.create([
        {
          date: "2022-09-13".to_date,
          count: 2,
          journey_pattern: journey_pattern1,
          route: route1,
          line: faulty_line
        },
        {
          date: "2022-09-14".to_date,
          count: 3,
          journey_pattern: journey_pattern1,
          route: route1,
          line: faulty_line
        },
        {
          date: "2022-09-13".to_date,
          count: 1,
          journey_pattern: journey_pattern2,
          route: route2,
          line: line
        }
      ])
    end

    let(:expected_message) do
      an_object_having_attributes({
        source: faulty_line,
        criticity: 'warning',
        message_attributes: {
          'name' => 'Faulty Line',
          'vehicle_journey_sum' => 5
        }
      })
    end

    it 'should detect the faulty line' do
      control_run.run

      expect(control_run.control_messages).to include(expected_message)
    end
  end
end
