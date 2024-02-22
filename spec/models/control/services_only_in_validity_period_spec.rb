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

    let(:context) do
      Chouette.create do
        workbench do
          line :faulty_line, name: 'Faulty Line', active_from: '2030-01-01'.to_date
          line :line
    
          referential do
            route(line: :faulty_line) do
              journey_pattern :journey_pattern1
            end
    
            route(line: :line) do
              journey_pattern :journey_pattern2
            end
          end
        end
      end
    end

    let(:workbench) { context.workbench }
    let(:referential) { context.referential }

    let(:line) { context.line(:line) }
    let(:faulty_line) { context.line(:faulty_line) }

    let(:route1) { journey_pattern1.route }
    let(:route2) { journey_pattern2.route }

    let(:journey_pattern1) { context.journey_pattern(:journey_pattern1) }
    let(:journey_pattern2) { context.journey_pattern(:journey_pattern2) }

    before do
      referential.switch

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
