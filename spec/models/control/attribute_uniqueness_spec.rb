# frozen_string_literal: true

RSpec.describe Control::AttributeUniqueness do
  describe Control::AttributeUniqueness::Run do
    let(:control_list_run) do
      Control::List::Run.create referential: referential, workbench: workbench
    end

    let(:context) do
      Chouette.create do
        stop_area_provider :other
        workbench :other

        referential do
          vehicle_journey :first, published_journey_name: 'duplicate'
          vehicle_journey :second, published_journey_name: 'duplicate'
          vehicle_journey :last
        end
      end
    end

    let(:control_run) do
      described_class.create(
        control_list_run: control_list_run,
        criticity: 'warning',
        target_model: target_model,
        target_attribute: target_attribute,
        uniqueness_scope: uniqueness_scope,
        position: 0
      )
    end

    let(:referential) { context.referential }
    let(:workbench) { referential.workbench }

    let(:first_duplicate_vehicle_journey) { context.vehicle_journey(:first) }
    let(:second_duplicate_vehicle_journey) { context.vehicle_journey(:second) }

    let(:first_duplicate_stop) { referential.stop_areas.first }
    let(:second_duplicate_stop) { referential.stop_areas.second }
    let(:last_stop) { referential.stop_areas.last }

    let(:stop_area_provider) { first_duplicate_stop.stop_area_provider }
  
    let(:other_workbench) { context.workbench(:other) }
    let(:other_stop_area_provider) { context.stop_area_provider(:other) }

    before do
      referential.switch
    end

    subject do
      control_run.run
      control_run.control_messages
    end

    describe '#run' do
      describe '#vehicle_journeys' do

        let(:target_model) { 'VehicleJourney' }
        let(:target_attribute) { 'published_journey_name' }
        let(:uniqueness_scope) { nil }

        let(:first_expected_message) do
          an_object_having_attributes(
            source: first_duplicate_vehicle_journey,
            criticity: 'warning',
          )
        end

        let(:second_expected_message) do
          an_object_having_attributes(
            source: first_duplicate_vehicle_journey,
            criticity: 'warning',
          )
        end

        it "should create warning messages" do
          is_expected.to include(first_expected_message)
          is_expected.to include(second_expected_message)
        end
      end

      describe '#stop_areas' do
        let(:target_model) { 'StopArea' }
        let(:target_attribute) { 'name' }

        before do
          first_duplicate_stop.update name: 'duplicate'
          second_duplicate_stop.update name: 'duplicate'
        end

        let(:first_expected_message) do
          an_object_having_attributes(
            source: first_duplicate_stop,
            criticity: 'warning',
          )
        end

        let(:second_expected_message) do
          an_object_having_attributes(
            source: second_duplicate_stop,
            criticity: 'warning',
          )
        end

        let(:not_expected_message) do
          an_object_having_attributes(
            source: last_stop,
            criticity: 'warning',
          )
        end

        context "When uniqueness scope is 'All'" do
          let(:uniqueness_scope) { 'all' }

          it 'should create warning messages' do
            is_expected.to include(first_expected_message)
            is_expected.to include(second_expected_message)
          end

          it 'should not ccreate message for the last stop area' do
            is_expected.not_to include(not_expected_message)
          end
        end

        context "When uniqueness scope is 'Provider'" do
          let(:uniqueness_scope) { 'provider' }

          context 'with the same provider' do
            it "should create warning messages" do
              is_expected.to include(first_expected_message)
              is_expected.to include(second_expected_message)
            end

            it 'should not ccreate message for the last stop area' do
              is_expected.not_to include(not_expected_message)
            end
          end

          context 'with other provider' do
            before do
              first_duplicate_stop.update stop_area_provider: other_stop_area_provider
            end

            it "should not create warning messages" do
              is_expected.to be_empty
            end
          end
        end

        context "When uniqueness scope is 'Workbench'" do
          let(:uniqueness_scope) { 'workbench' }

          before do
            first_duplicate_stop.update stop_area_provider: other_stop_area_provider
          end

          context 'with the same workbench' do
            it "should create warning messages" do
              is_expected.to include(first_expected_message)
              is_expected.to include(second_expected_message)
            end
          end

          context 'with other provider' do
            before do 
              stop_area_provider.update workbench: other_workbench
            end

            it "should not create warning messages" do
              is_expected.to be_empty
            end
          end
        end
      end
    end
  end
end
