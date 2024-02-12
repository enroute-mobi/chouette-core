# frozen_string_literal: true

RSpec.describe Control::ServiceCountInRange do
  it 'should be one of the available Control' do
    expect(Control.available).to include(described_class)
  end

  describe Control::ServiceCountInRange::Run do
    let(:control_list_run) do
      Control::List::Run.create referential: referential, workbench: workbench
    end

    let(:control_run) do
      control_run = described_class.create(
        control_list_run: control_list_run,
        criticity: "warning",
        minimum_service_counts: 2,
        maximum_service_counts: 10,
        position: 0
      )
    end

    let(:first_journey_pattern) { create :journey_pattern }
    let(:second_journey_pattern) { create :journey_pattern }
    let(:third_journey_pattern) { create :journey_pattern }


    let(:line_referential) { create :line_referential }
    let(:workbench) { create :workbench, line_referential: line_referential }

    let!(:first_faulty_line) { create :line, line_referential: line_referential }
    let!(:second_faulty_line) { create :line, line_referential: line_referential }
    let!(:third_line) { create :line, line_referential: line_referential }

    let(:first_route) { first_journey_pattern.route }
    let(:second_route) { second_journey_pattern.route }
    let(:third_route) { third_journey_pattern.route }

    let(:referential)  { create :workbench_referential, workbench: workbench }
  
    before do
      referential.switch
      first_journey_pattern.route.update line: first_faulty_line
      second_journey_pattern.route.update line: second_faulty_line

      ServiceCount.create([
        {
          date: "2022-09-13".to_date,
          count: 100,
          journey_pattern: first_journey_pattern,
          route: first_route,
          line: first_faulty_line
        },
        {
          date: "2022-09-20".to_date,
          count: 6,
          journey_pattern: first_journey_pattern,
          route: first_route,
          line: first_faulty_line
        },

        {
          date: "2022-09-13".to_date,
          count: 4,
          journey_pattern: second_journey_pattern,
          route: second_route,
          line: second_faulty_line
        },
        {
          date: "2022-09-20".to_date,
          count: 1,
          journey_pattern: second_journey_pattern,
          route: second_route,
          line: second_faulty_line
        },

        {
          date: "2022-09-01".to_date,
          count: 5,
          journey_pattern: third_journey_pattern,
          route: third_route,
          line: third_line
        },
        {
          date: "2022-09-02".to_date,
          count: 6,
          journey_pattern: third_journey_pattern,
          route: third_route,
          line: third_line
        },
      ])

    end

    let(:first_expected_message) do
      an_object_having_attributes({
        source: first_faulty_line,
        criticity: 'warning',
        message_attributes: {
          'date' => '2022-09-13',
          'line' => first_faulty_line.name
        }
      })
    end

    let(:second_expected_message) do
      an_object_having_attributes({
        source: second_faulty_line,
        criticity: 'warning',
        message_attributes: {
          'date' => '2022-09-20',
          'line' => second_faulty_line.name
        }
      })
    end

    it 'should detect the anomalies' do
      control_run.run

      expect(control_run.control_messages).to contain_exactly(first_expected_message, second_expected_message)
    end
  end
end
