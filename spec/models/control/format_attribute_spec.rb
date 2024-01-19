# frozen_string_literal: true

RSpec.describe Control::FormatAttribute do
  it 'should be one of the available Control' do
    expect(Control.available).to include(described_class)
  end

  describe Control::FormatAttribute::Run do
    it { should validate_presence_of :target_model }
    it { should validate_presence_of :target_attribute }
    it { should validate_presence_of :expected_format }
    it do
      should enumerize(:target_model).in(
        %w[Line StopArea Route JourneyPattern VehicleJourney Company Entrance PointOfInterest Document Shape Network
           ConnectionLink]
      )
    end

    it 'should validate_presence of :model_attribute' do
      valid_control_run = described_class.new target_model: 'Line', target_attribute: 'name'

      valid_control_run.valid?

      expect(valid_control_run.model_attribute).to be
      expect(valid_control_run.errors.details[:model_attribute]).to be_empty

      invalid_control_run = described_class.new target_model: 'Line', target_attribute: 'names'

      invalid_control_run.valid?

      expect(invalid_control_run.model_attribute).to be_nil
      expect(invalid_control_run.errors.details[:model_attribute]).not_to be_empty
    end

    describe '#candidate_target_attributes' do
      subject { described_class.new.candidate_target_attributes }

      it 'does not cause error' do
        expect(Rails.logger).not_to receive(:error)
        subject
      end
    end

    let(:control_list_run) do
      Control::List::Run.create referential: context.referential, workbench: context.workbench
    end

    let(:target_attribute) { 'name' }
    let(:expected_format) { '[BFHJ][0-9]{4,6}-[A-Z]{3}' }

    let(:control_run) do
      Control::FormatAttribute::Run.create(
        control_list_run: control_list_run,
        criticity: 'warning',
        options: { target_model: target_model, target_attribute: target_attribute, expected_format: expected_format },
        position: 0
      )
    end

    describe '#run' do
      subject { control_run.run }

      let(:referential) { context.referential }

      let(:expected_message) do
        an_object_having_attributes({
                                      source: source,
                                      criticity: 'warning',
                                      message_attributes: {
                                        'name' => source.try(:name) || source.id,
                                        'expected_format' => expected_format,
                                        'target_attribute' => target_attribute
                                      }
                                    })
      end

      describe '#StopArea' do
        let(:context) do
          Chouette.create do
            stop_area :with_a_good_name, name: 'B9999-AAA'
            stop_area :with_a_bad_name, name: 'BAD_CODE'
            referential do
              route stop_areas: [:with_a_good_name, :with_a_bad_name]
            end
          end
        end

        before { referential.switch }
        let(:target_model) { 'StopArea' }
        let(:source) { context.stop_area(:with_a_bad_name) }
        let(:stop_area_with_a_good_name) { context.stop_area(:with_a_good_name) }

        it 'should create messages for stop areas without good attribute format' do
          subject

          expect(control_run.control_messages).to contain_exactly(expected_message)
        end
      end

      describe '#Entrance' do
        let(:context) do
          Chouette.create do
            stop_area :departure do
              entrance :good_name, name: 'B9999-AAA'
              entrance :bad_name, name: 'BAD_NAME'
            end
            stop_area :arrival

            referential do
              route stop_areas: [:departure, :arrival]
            end
          end
        end

        before { referential.switch }
        let(:target_model) { 'Entrance' }
        let(:source) { context.entrance(:bad_name) }

        it 'should create messages for entrances with bad attribute format' do
          subject

          expect(control_run.control_messages).to contain_exactly(expected_message)
        end
      end
    end
  end
end
