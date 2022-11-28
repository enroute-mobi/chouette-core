RSpec.describe Control::Speed do

  describe Control::Speed::Run do

    let(:control_list_run) do
      Control::List::Run.create referential: referential, workbench: workbench
    end

    let(:control_run) do
      control_run= Control::Speed::Run.create(
        control_list_run: control_list_run,
        criticity: "warning",
        minimum_speed: 144, # 40km/h
        maximum_speed: 216, # 60km/h
        minimum_distance: 1,
        position: 0
      )
    end

    let(:context) do
      Chouette.create do
        stop_area :first, id: 1000, name: 'first'
        stop_area :middle, id: 2000, name: 'second'
        stop_area :third, id: 3000, name: 'third'
        stop_area :last, id: 4000, name: 'last'

        referential do
          route stop_areas: [:first, :middle, :third, :last] do
            journey_pattern name: 'JP name'
          end
        end
      end
    end

    let(:referential) { context.referential }
    let(:workbench) { context.workbench }
    let(:journey_pattern) { context.journey_pattern }

    before do
      referential.switch
      journey_pattern.update costs: { 
        '1000-2000' => { 'time' => 10, 'distance' => 2160 },
        '2000-3000' => { 'time' => 30, 'distance' => 12000000 },
        '3000-4000' => { 'time' => 20, 'distance' => 100 } 
      } 
    end

    def stop_area(name)
      context.stop_area(name).reload
    end
  
    let(:expected_message) do
      an_object_having_attributes({
        source: journey_pattern,
        criticity: 'warning',
        message_attributes: {
          'faulty_stop_area_pairs' => 'second - third; third - last',
          'journey_pattern_name' => 'JP name'
        }
      })
    end

    it 'should detect anomaly' do
      control_run.run

      expect(control_run.control_messages).to include(expected_message)
    end
  end
end