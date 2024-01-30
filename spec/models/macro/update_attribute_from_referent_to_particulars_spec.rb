# frozen_string_literal: true

RSpec.describe Macro::UpdateAttributeFromReferentToParticulars do
  it 'should be one of the available Macro' do
    expect(Macro.available).to include(described_class)
  end
end

RSpec.describe Macro::UpdateAttributeFromReferentToParticulars::Run do
  it { should validate_presence_of :target_model }
  it { should validate_presence_of :target_attribute }
  it do
    should enumerize(:target_model).in(
      %w[StopArea Company]
    )
  end
  it do
    should enumerize(:override_existing_value).in(
      %w[true false]
    )
  end

  let(:macro_list_run) do
    Macro::List::Run.create workbench: context.workbench
  end
  let(:macro_run) do
    described_class.create(
      macro_list_run: macro_list_run,
      position: 0,
      options: { target_model: target_model, target_attribute: target_attribute,
                 override_existing_value: override_existing_value }
    )
  end

  let(:context) do
    Chouette.create do
      stop_area :referent, is_referent: true, time_zone: 'Europe/Paris'
      stop_area :first_particular, time_zone: nil, referent: :referent
      stop_area :second_particular, time_zone: nil, referent: :referent

      referential
    end
  end

  before { context.referential.switch }

  describe '#run' do
    let(:referent) { context.stop_area(:referent) }
    let(:target_model) { 'StopArea' }
    let(:target_attribute) { 'time_zone' }
    let(:override_existing_value) { false }

    subject { macro_run.run }

    let(:first_particular) { context.stop_area(:first_particular) }
    let(:second_particular) { context.stop_area(:second_particular) }

    it 'should update time_zone from referent to particulars' do
      expect { subject }.to change { first_particular.reload.time_zone }.from(nil).to('Europe/Paris')
                        .and change { second_particular.reload.time_zone }.from(nil).to('Europe/Paris')
    end

    it 'should create a macro message' do
      expect { subject }.to change { macro_run.macro_messages.count }.from(0).to(2)

      first_expected_message = an_object_having_attributes(
        criticity: 'info',
        message_attributes: {
          'name' => first_particular.name,
          'attribute_name' => first_particular.class.human_attribute_name('time_zone'),
          'attribute_value' => 'Europe/Paris'
        },
        source: first_particular
      )

      second_expected_message = an_object_having_attributes(
        criticity: 'info',
        message_attributes: {
          'name' => second_particular.name,
          'attribute_name' => second_particular.class.human_attribute_name('time_zone'),
          'attribute_value' => 'Europe/Paris'
        },
        source: second_particular
      )

      expect(macro_run.macro_messages).to include(first_expected_message)
      expect(macro_run.macro_messages).to include(second_expected_message)
    end

    context 'when value is already present' do
      let(:context) do
        Chouette.create do
          stop_area :referent, is_referent: true, time_zone: 'Europe/Paris'
          stop_area :first_particular, time_zone: 'Europe/Berlin', referent: :referent
          stop_area :second_particular, time_zone: 'Europe/Berlin', referent: :referent

          referential
        end
      end

      it 'should not update time_zone from referent to particulars' do
        expect { subject }.to(
          not_change { first_particular.reload.time_zone }.and(
            not_change { second_particular.reload.time_zone }
          )
        )
      end

      it 'should not create a macro message' do
        expect { subject }.not_to(change { macro_run.macro_messages.count })
      end

      context 'when override_existing_value is true' do
        let(:override_existing_value) { 'true' }

        it 'should update time_zone from referent to particulars' do
          expect { subject }.to change { first_particular.reload.time_zone }.from('Europe/Berlin').to('Europe/Paris')
                            .and change { second_particular.reload.time_zone }.from('Europe/Berlin').to('Europe/Paris')
        end

        it 'should create a macro message' do
          expect { subject }.to change { macro_run.macro_messages.count }.from(0).to(2)
        end
      end
    end
  end
end
