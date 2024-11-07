# frozen_string_literal: true

RSpec.describe Control::AttributeUniqueness do
  describe Control::AttributeUniqueness::Run do
    let(:control_list_run) do
      Control::List::Run.create referential: referential, workbench: workbench
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

    subject do
      control_run.run
      control_run.control_messages
    end

    describe '#run' do
      context 'for Vehicle journeys' do
        let(:context) do
          Chouette.create do
            referential do
              vehicle_journey :first, published_journey_name: 'duplicate', published_journey_identifier: 'id_1'
              vehicle_journey :second, published_journey_name: 'duplicate', published_journey_identifier: 'id_2'
            end
          end
        end

        let(:first_duplicate_vehicle_journey) { context.vehicle_journey(:first) }
        let(:second_duplicate_vehicle_journey) { context.vehicle_journey(:second) }
        let(:referential) { context.referential }
        let(:workbench) { context.referential.workbench }

        let(:target_model) { 'VehicleJourney' }
        let(:target_attribute) { 'published_journey_name' }
        let(:uniqueness_scope) { nil }

        let(:first_expected_message) do
          an_object_having_attributes(
            source: first_duplicate_vehicle_journey,
            message_attributes: {
              'id' => 'id_1',
              'name' => 'duplicate',
              'target_attribute' => 'published_journey_name'
            },
            criticity: 'warning'
          )
        end

        let(:second_expected_message) do
          an_object_having_attributes(
            source: second_duplicate_vehicle_journey,
            message_attributes: {
              'id' => 'id_2',
              'name' => 'duplicate',
              'target_attribute' => 'published_journey_name'
            },
            criticity: 'warning'
          )
        end

        before do
          referential.switch
        end

        it 'should create warning messages for duplicated vehicle journeys' do
          is_expected.to include(first_expected_message)
          is_expected.to include(second_expected_message)
        end
      end

      describe 'for Stop areas' do
        let(:target_model) { 'StopArea' }
        let(:target_attribute) { 'name' }

        let(:first_duplicate_stop) { context.stop_area(:first) }
        let(:second_duplicate_stop) { context.stop_area(:second) }
        let(:referential) { nil }
        let(:workbench) { context.workbench(:first) }

        let(:first_expected_message) do
          an_object_having_attributes(
            source: first_duplicate_stop,
            criticity: 'warning'
          )
        end

        let(:second_expected_message) do
          an_object_having_attributes(
            source: second_duplicate_stop,
            criticity: 'warning'
          )
        end

        context "When uniqueness scope is 'All'" do
          let(:uniqueness_scope) { 'all' }

          let(:context) do
            Chouette.create do
              workbench :first do
                stop_area :first, name: 'duplicate'
              end
              workbench :second do
                stop_area :second, name: 'duplicate'
              end
            end
          end

          it 'should create warning messages for duplicated stop areas' do
            is_expected.to include(first_expected_message)
            is_expected.to include(second_expected_message)
          end
        end

        context "When uniqueness scope is 'Provider'" do
          let(:uniqueness_scope) { 'provider' }

          context 'with the same provider' do

            let(:context) do
              Chouette.create do
                workbench :first do
                  stop_area :first, name: 'duplicate'
                  stop_area :second, name: 'duplicate'
                end
              end
            end

            it 'should create warning messages for duplicated stop areas' do
              is_expected.to include(first_expected_message)
              is_expected.to include(second_expected_message)
            end
          end

          context 'with other provider' do

            let(:context) do
              Chouette.create do
                workbench :first do
                  stop_area_provider :first do
                    stop_area :first, name: 'duplicate'
                  end
                  stop_area_provider :second do
                    stop_area :second, name: 'duplicate'
                  end
                end
              end
            end

            it 'should not create warning messages' do
              is_expected.to be_empty
            end
          end
        end

        context "When uniqueness scope is 'Workbench'" do
          let(:uniqueness_scope) { 'workbench' }

          context 'with the same workbench' do
            let(:context) do
              Chouette.create do
                workbench :first do
                  stop_area :first, name: 'duplicate'
                  stop_area :second, name: 'duplicate'
                end
              end
            end

            it 'should create warning messages for duplicated stop areas' do
              is_expected.to include(first_expected_message)
              is_expected.to include(second_expected_message)
            end
          end

          context 'with other workbench' do

            let(:context) do
              Chouette.create do
                workbench :first do
                  stop_area :first, name: 'duplicate'
                end
                workbench :second do
                  stop_area :second, name: 'duplicate'
                end
              end
            end

            it 'should not create warning messages' do
              is_expected.to be_empty
            end
          end
        end
      end
    end
  end
end
