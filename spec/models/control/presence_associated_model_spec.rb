# frozen_string_literal: true

RSpec.describe Control::PresenceAssociatedModel do
  describe Control::PresenceAssociatedModel::Run do
    describe '#candidate_collections' do
      subject { described_class.new.candidate_collections }

      it 'does not cause error' do
        expect(Rails.logger).not_to receive(:error)
        subject
      end
    end

    let(:control_list_run) do
      Control::List::Run.create referential: context.referential, workbench: context.workbench
    end

    let(:control_run) do
      Control::PresenceAssociatedModel::Run.create(
        control_list_run: control_list_run,
        criticity: 'warning',
        options: {
          target_model: target_model,
          collection: collection,
          minimum: min,
          maximum: max
        },
        position: 0
      )
    end

    describe '#run' do
      subject { control_run.run }

      let(:context) do
        Chouette.create do
          shape :shape
          referential do
            route :route do
              journey_pattern shape: :shape
            end
          end
        end
      end

      let(:referential) { context.referential }

      let(:expected_message) do
        an_object_having_attributes(source: source,
                                    criticity: criticity,
                                    message_attributes: { 'name' => attribute_name, 'count' => 1 })
      end

      before do
        referential.switch
      end

      describe 'Routes' do
        let(:route) { context.route(:route) }
        let(:source) { route }
        let(:attribute_name) { route.name }
        let(:target_model) { 'Route' }

        describe '#journey_patterns' do
          let(:collection) { 'journey_patterns' }

          let(:criticity) { 'warning' }

          context 'when number of model associated is not in the range [min, max]' do
            let(:min) { 9 }
            let(:max) { 10 }

            it 'should create warning message' do
              subject

              expect(control_run.control_messages).to include(expected_message)
            end
          end

          context 'when number of model associated is in the range [min, max]' do
            let(:min) { 1 }
            let(:max) { 10 }

            it 'should not create warning message' do
              subject

              expect(control_run.control_messages).to be_empty
            end
          end
        end
      end
    end
  end
end
