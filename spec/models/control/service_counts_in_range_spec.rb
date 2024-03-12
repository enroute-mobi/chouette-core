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

    let(:context) do
      Chouette.create do
        line :first
        line :second
        line :third

        referential do
          route :first, line: :first do
            journey_pattern :first
          end

          route :second, line: :second do
            journey_pattern :second
          end

          route :third, line: :third do
            journey_pattern :third
          end
        end
      end
    end

    let(:first_journey_pattern) { context.journey_pattern(:first) }
    let(:second_journey_pattern) { context.journey_pattern(:second) }
    let(:third_journey_pattern) { context.journey_pattern(:third) }

    let(:workbench) { context.workbench }

    let(:first_faulty_line) { first_route.line }
    let(:second_faulty_line) { second_route.line }
    let(:third_line) { third_route.line }

    let(:first_route) { context.route :first }
    let(:second_route) { context.route :second }
    let(:third_route) { context.route :third }

    let(:referential)  { context.referential}
  
    before do
      referential.switch

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
