# frozen_string_literal: true

RSpec.describe Macro::DefineRouteName do
  it 'should be one of the available Macro' do
    expect(Macro.available).to include(described_class)
  end

  describe Macro::DefineRouteName::Run do
    let(:macro_run) do
      described_class.create(
        macro_list_run: macro_list_run,
        position: 0,
        target_attribute: target_attribute,
        target_format: 'Test %{direction} - %{departure.name} > %{arrival.name}'
      )
    end

    let(:macro_list_run) do
      Macro::List::Run.create referential: referential, workbench: workbench
    end

    describe '#run' do
      subject { macro_run.run }

      let(:context) do
        Chouette.create do
          stop_area :first, name: 'First'
          stop_area :middle, name: 'Middle'
          stop_area :last, name: 'Last'

          referential do
            route :first, name: 'Route', stop_areas: %i[first middle last]
          end
        end
      end

      let(:referential) { context.referential }
      let(:workbench) { context.workbench }
      let(:first_stop_area) { context.stop_area(:first) }
      let(:last_stop_area) { context.stop_area(:last) }
      let(:route) { context.route(:first) }
      let(:attribute_value) { 'Test Aller - First > Last' }
      let(:name_before_change) { 'Route' }

      let(:expected_message) do
        an_object_having_attributes(
          message_attributes: {
            'name_before_change' => name_before_change,
            'attribute_value_after_change' => attribute_value
          },
          source: route
        )
      end

      before { referential.switch }

      context "when target_attribute is 'name'" do
        let(:target_attribute) { :name }

        it 'should update route name' do
          expect { subject }.to change { route.reload.name }.from('Route').to(attribute_value)
          expect(macro_run.macro_messages).to include(expected_message)
        end
      end

      context "when target_attribute is 'direction'" do
        let(:target_attribute) { :published_name }

        it 'should update route diretion name' do
          expect { subject }.to change { route.reload.published_name }.from(nil).to(attribute_value)
          expect(macro_run.macro_messages).to include(expected_message)
        end
      end
    end
  end
end
