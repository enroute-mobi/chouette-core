# frozen_string_literal: true

RSpec.describe Macro::DefineAttributeFromParticulars::Run do
  let(:macro_list_run) do
    Macro::List::Run.create workbench: context.workbench
  end
  let(:macro_run) do
    described_class.create(
      macro_list_run: macro_list_run,
      position: 0,
      options: { target_model: target_model, target_attribute: target_attribute }
    )
  end

  let(:context) do
    Chouette.create { workbench }
  end

  describe '#run' do
    let(:referent) { context.stop_area(:referent) }
    let(:target_model) { 'StopArea' }

    subject { macro_run.run }

    describe '#time_zone' do
      let(:target_attribute) { 'time_zone' }

      context 'when referent attribute is undefined and one particular have defined value' do
        let(:context) do
          Chouette.create do
            stop_area :referent, is_referent: true, time_zone: nil
            stop_area time_zone: 'Europe/Paris', referent: :referent
          end
        end

        it 'should update referent attribute with particular value' do
          expect { subject }.to change { referent.reload.time_zone }.from(nil).to('Europe/Paris')
        end

        it 'should create a macro message' do
          expect { subject }.to change { macro_run.macro_messages.count }.from(0).to(1)

          expected_message = an_object_having_attributes(
            criticity: 'info',
            message_attributes: {
              'name' => referent.name,
              'attribute_name' => referent.class.human_attribute_name('time_zone'),
              'attribute_value' => 'Europe/Paris'
            },
            source: referent
          )
          expect(macro_run.macro_messages).to include(expected_message)
        end
      end

      context 'when referent attribute is undefined and all particulars have the same defined value' do
        let(:context) do
          Chouette.create do
            stop_area :referent, is_referent: true, time_zone: nil
            stop_area time_zone: 'Europe/Paris', referent: :referent
            stop_area time_zone: 'Europe/Paris', referent: :referent
          end
        end

        it 'should update referent attribute with particulars value' do
          expect { subject }.to change { referent.reload.time_zone }.from(nil).to('Europe/Paris')
        end
      end

      context 'when referent attribute is undefined and particulars have different defined value' do
        let(:context) do
          Chouette.create do
            stop_area :referent, is_referent: true, time_zone: nil
            stop_area time_zone: 'Europe/Paris', referent: :referent
            stop_area time_zone: 'Europe/London', referent: :referent
          end
        end

        it 'should not update referent attribute' do
          expect { subject }.to_not change { referent.reload.time_zone }
        end
      end

      context 'when referent attribute is already defined' do
        let(:context) do
          Chouette.create do
            stop_area :referent, is_referent: true, time_zone: 'Europe/Paris'
            stop_area time_zone: 'Europe/London', referent: :referent
          end
        end

        it 'should not update referent attribute' do
          expect { subject }.to_not change { referent.time_zone }
        end
      end
    end

    { mobility_impaired_accessibility: 'yes', wheelchair_accessibility: 'yes', step_free_accessibility: 'yes',
      escalator_free_accessibility: 'yes', lift_free_accessibility: 'yes', audible_signals_availability: 'yes',
      visual_signs_availability: 'yes', accessibility_limitation_description: 'Accessibility limitation description'
    }.each do |target_attribute, attribute_value|
      describe "##{target_attribute}" do
        let(:target_attribute) { target_attribute }
        let(:context) do
          Chouette.create do
            stop_area :referent, is_referent: true
            stop_area target_attribute => attribute_value, referent: :referent
          end
        end

        let(:old_attribute_value) { referent.send(target_attribute) }

        it "should update referent '#{target_attribute}' with particular value '#{attribute_value}'" do
          expect { subject }.to change { referent.reload.send(target_attribute) }.from(old_attribute_value).to(attribute_value)
        end

        it 'should create a macro message' do
          expect { subject }.to change { macro_run.macro_messages.count }.from(0).to(1)

          expected_message = an_object_having_attributes(
            criticity: 'info',
            message_attributes: {
              'name' => referent.name,
              'attribute_name' => referent.class.human_attribute_name(target_attribute.to_s),
              'attribute_value' => attribute_value
            },
            source: referent
          )
          expect(macro_run.macro_messages).to include(expected_message)
        end
      end
    end
  end

  describe '#particulars' do
    let(:target_model) { 'StopArea' }
    let(:target_attribute) { 'time_zone' }

    subject { macro_run.particulars }

    let(:context) do
      Chouette.create do
        stop_area :referent, is_referent: true
        stop_area :particular, referent: :referent, time_zone: 'Europe/Paris'
        stop_area
      end
    end

    let(:stop_area) { context.stop_area(:particular) }

    it { is_expected.to contain_exactly(stop_area) }
  end

  describe '#referents' do
    let(:target_model) { 'StopArea' }
    let(:target_attribute) { 'time_zone' }

    subject { macro_run.referents }

    let(:context) do
      Chouette.create do
        stop_area :referent1, is_referent: true
        stop_area :referent2, is_referent: true
        stop_area :particular, referent: :referent
      end
    end

    it { is_expected.to contain_exactly(context.stop_area(:referent1), context.stop_area(:referent2)) }
  end
end
